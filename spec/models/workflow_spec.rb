require 'spec_helper'

describe Workflow, type: :model do
  let(:workflow) { build(:workflow) }
  let(:subject_relation) { create(:workflow_with_subjects) }

  it_behaves_like "optimistically locked" do
    let(:locked_factory) { :workflow }
    let(:locked_update) { {display_name: "A Different Name"} }
  end

  it_behaves_like "has subject_count"

  it_behaves_like "has content" do
    let(:translatable) { create(:workflow_with_contents, build_extra_contents: true) }
    let(:translatable_without_content) { build(:workflow, build_contents: false) }
    let(:primary_language_factory) { :workflow }
    let(:private_project) { create(:project, private: true) }
    let(:private_model) { create(:workflow, project: private_project) }
  end

  it_behaves_like "activatable" do
    let(:activatable) { workflow }
  end

  context "with caching resource associations" do
    let(:cached_resource) { workflow }

    it_behaves_like "has an extended cache key" do
      let(:methods) do
        %i(subjects_count finished?)
      end
    end
  end

  it "should have a valid factory" do
    expect(workflow).to be_valid
  end

  describe "::find_without_json_attrs" do
    let(:workflow) { create(:workflow) }
    let(:json_attrs) do
      %w(tasks retirement aggregation configuration)
    end
    let(:non_json_attrs) do
      Workflow.attribute_names - json_attrs
    end

    it "should load the workflow without the tasks attribute" do
      expect(Workflow)
        .to receive(:select)
        .with(*non_json_attrs)
        .and_call_original
      no_json_workflow = Workflow.find_without_json_attrs(workflow.id)
      expect(no_json_workflow.id).to eq(workflow.id)
    end
  end

  describe "#display_name" do
    let(:workflow) { build(:workflow, display_name: nil) }

    it "should not be valid", :aggregate_failures do
      validity = workflow.valid?
      expect(validity).to be_falsey
      expect(workflow.errors[:display_name]).to_not be_nil
    end
  end

  it "should be destroyable when it has subject counts" do
    workflow.save!
    create(:subject_workflow_status, workflow: workflow)
    expect{ workflow.destroy }.to_not raise_error
  end

  it "should only have a subject set assigned once" do
    ss = create(:subject_set)
    workflow.subject_sets << ss
    workflow.save!
    expect do
      workflow.subject_sets << ss
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  describe "#project" do
    let(:workflow) { create(:workflow) }

    it "should have a project" do
      expect(workflow.project).to be_a(Project)
    end

    it "should belong to a project to be valid" do
      expect(build(:workflow, project: nil)).to_not be_valid
    end
  end

  describe "#subject_sets" do
    let(:workflow) { create(:workflow_with_subject_sets) }

    it "should have many subject sets" do
      expect(workflow.subject_sets).to all( be_a(SubjectSet) )
    end
  end

  describe "#classifications" do
    let(:relation_instance) { workflow }

    it_behaves_like "it has a classifications assocation"
  end

  describe 'publishing', versioning: true do
    let(:workflow) { create(:workflow, tasks: {version: 1}) }

    it 'works with the first version' do
      workflow.publish!
      workflow.update!(tasks: {version: 2})
      workflow.update!(tasks: {version: 3})
      workflow.update!(tasks: {version: 4})

      active_version = workflow.published_version
      expect(active_version.tasks).to eq("version" => 1)
    end

    it 'works with an in-between version' do
      workflow.update!(tasks: {version: 2})
      workflow.update!(tasks: {version: 3})
      workflow.publish!
      workflow.update!(tasks: {version: 4})

      active_version = workflow.published_version
      expect(active_version.tasks).to eq("version" => 3)
    end

    it 'works with the latest version' do
      workflow.update!(tasks: {version: 2})
      workflow.update!(tasks: {version: 3})
      workflow.update!(tasks: {version: 4})
      workflow.publish!

      active_version = workflow.published_version
      expect(active_version.tasks).to eq("version" => 4)
    end

    it 'publishes primary content' do
      workflow.update(strings: {version: "one"})
      workflow.publish!
      workflow.update(strings: {version: "two"})

      active_version = Workflow.find(workflow.id).published_version
      expect(active_version.strings).to eq("version" => "one")
    end
  end

  describe "versioning", versioning: true do
    let(:workflow) { create(:workflow, tasks: {version: 1}) }

    it { is_expected.to be_versioned }

    it 'should track changes to tasks' do
      new_tasks = { blha: 'asdfasd', quera: "asdfas" }
      workflow.update!(tasks: new_tasks)
      expect(workflow.previous_version.tasks).to_not eq(new_tasks)
    end

    it 'should not track changes to primary_language' do
      new_lang = 'en'
      workflow.update!(primary_language: new_lang)
      expect(workflow.previous_version).to be_nil
    end

    it 'caches the new version number', :aggregate_failures do
      previous_number = workflow.current_version_number.to_i
      workflow.update!(tasks: {blha: 'asdfasd', quera: "asdfas"})
      expect(workflow.current_version_number.to_i).to eq(previous_number + 1)
      expect(workflow.current_version_number.to_i).to eq(ModelVersion.version_number(workflow))
    end

    it 'tracks major version number' do
      expect do
        workflow.update!(tasks: {blha: 'asdfasd', quera: "asdfas"})
      end.to change { workflow.major_version }.by(1)

      expect do
        workflow.update!(strings: {})
      end.not_to change { workflow.major_version }
    end

    it 'tracks minor version number' do
      expect do
        workflow.update!(strings: {a: 4})
      end.to change { workflow.minor_version }.by(1)

      expect do
        workflow.update!(tasks: {blha: 'asdfasd', quera: "asdfas"})
      end.not_to change { workflow.minor_version }
    end
  end

  describe "#retirement_scheme" do
    subject { build(:workflow, retirement: retirement) }

    context "empty" do
      let(:retirement) { Hash.new }

      it "should return a classification count scheme" do
        expect(subject.retirement_scheme).to be_a(RetirementSchemes::ClassificationCount)
      end
    end

    context 'never_retire' do
      let(:retirement) { { 'criteria' => 'never_retire', 'options' => {} } }

      it "should return a never retire scheme" do
        expect(subject.retirement_scheme).to be_a(RetirementSchemes::NeverRetire)
      end
    end

    context "classification_count" do
      let(:retirement) do
        { 'criteria' => 'classification_count', 'options' => {'count' => 1} }
      end

      it "should return a classification count scheme" do
        expect(subject.retirement_scheme).to be_a(RetirementSchemes::ClassificationCount)
      end
    end

    context "anything else" do
      let(:retirement) { { 'criteria' => 'anything else', 'options': {} } }

      it 'should raise an error' do
        expect{subject.retirement_scheme}.to raise_error(StandardError, 'invalid retirement scheme')
      end
    end
  end

  describe "#retirement" do
    subject { build(:workflow, retirement: retirement) }

    context "empty" do
      let(:retirement) { Hash.new }

      it { is_expected.to be_valid }
    end

    context "classification_count" do
      let(:retirement) { { 'criteria' => 'classification_count' } }

      it { is_expected.to be_valid }

      describe "empty count vales" do
        let(:retirement) do
          {
            'criteria' => 'classification_count',
            'options' => { 'count' =>nil }
           }
        end

        it "should not be valid" do
          expect(subject.valid?).to eq(false)
        end

        it "should have a useful error message" do
          subject.valid?
          expected_msg = "Retirement count must be a number"
          expect(
            subject.errors[:"retirement.options.count"]
          ).to match_array([expected_msg])
        end
      end
    end

    context "anything else" do
      let(:retirement) { { 'criteria' => 'anything else' } }

      it { is_expected.to_not be_valid }
    end
  end

  describe "#retirement_with_defaults" do
    let(:workflow) { build(:workflow, retirement: retirement) }
    let(:defaults) { Workflow::DEFAULT_RETIREMENT_OPTIONS }

    context "empty" do
      let(:retirement) { Hash.new }

      it "should return default values" do
        expect(workflow.retirement_with_defaults).to eq(defaults)
      end
    end

    context "with criteria" do
      let(:retirement) { { 'criteria' => 'classification_count' } }

      it "should return non-defaults" do
        expect(workflow.retirement_with_defaults).to eq(retirement)
      end
    end
  end

  describe '#retire_subject' do
    let(:workflow) { create(:workflow_with_subject_sets) }
    let(:subject)  { create(:subject, subject_sets: workflow.subject_sets) }

    context 'when the subject has a workflow count' do
      it 'marks as retired' do
        create(:subject_workflow_status, subject: subject, workflow: workflow)
        workflow.retire_subject(subject.id)

        aggregate_failures do
          expect(subject.retired_for_workflow?(workflow)).to be_truthy
          expect(SubjectWorkflowStatus.retired.count).to eq(1)
        end
      end
    end

    context 'when the subject does not have a workflow count' do
      it 'marks as retired' do
        workflow.retire_subject(subject.id)

        aggregate_failures do
          expect(subject.retired_for_workflow?(workflow)).to be_truthy
          expect(SubjectWorkflowStatus.retired.count).to eq(1)
        end
      end
    end

    context 'when the subject is already retired' do
      it 'leaves the retirement timestamp as it was' do
        workflow.retire_subject(subject.id)
        retired_ats = SubjectWorkflowStatus.order(:id).pluck(:retired_at)
        workflow.retire_subject(subject.id)

        aggregate_failures do
          expect(subject.retired_for_workflow?(workflow)).to be_truthy
          expect(SubjectWorkflowStatus.retired.count).to eq(1)
          expect(SubjectWorkflowStatus.order(:id).pluck(:retired_at)).to eq(retired_ats)
        end
      end
    end

    context 'when the subject does not belong to the workflow' do
      let(:subject) { create(:subject) }

      it 'should retire the subject' do
        expect {
          workflow.retire_subject(subject.id)
        }.to change { SubjectWorkflowStatus.retired.count }.by(1)
      end
    end
  end

  describe '#retired_subjects' do
    it 'returns through subject association' do
      sms = create(:set_member_subject)
      swc = create(:subject_workflow_status, subject: sms.subject, retired_at: Time.now)

      expect(swc.workflow.retired_subjects).to eq([sms.subject])
    end
  end

  describe "#retired_subjects_count" do
    it "should be an alias for retired set_member_subjects count" do
      expect(subject_relation.retired_subjects_count).to eq(subject_relation.retired_set_member_subjects_count)
    end
  end

  describe "#finished?" do
    let(:workflow) { subject_relation }
    let(:subjects_count) { workflow.subjects_count }

    context "when no subject_sets relation exist" do
      it 'should be false' do
        allow(workflow).to receive(:subject_sets).and_return([])
        expect(workflow).not_to be_finished
      end
    end

    context "when the workflow is marked finished" do
      before do
        allow(workflow).to receive(:finished_at).and_return(Time.zone.now)
      end

      it 'should be true' do
        expect(workflow).to be_finished
      end
    end

    context "when the workflow is not marked finished" do
      it 'should be false if the retired < subjects count' do
        expect(workflow).not_to be_finished
      end

      it 'should be true if the retired >= subjects count' do
        allow(workflow).to receive(:retired_subjects_count).and_return(subjects_count)
        expect(workflow).to be_finished
        allow(workflow).to receive(:retired_subjects_count).and_return(subjects_count+1)
        expect(workflow).to be_finished
      end
    end
  end

  describe "#aggregation" do
    let(:workflow) { build(:workflow, aggregation: aggregation_config ) }

    context "empty" do
      let(:aggregation_config) { Hash.new }

      it "should be valid" do
        expect(workflow).to be_valid
      end
    end

    context "with values" do
      let(:aggregation_config) { { public: true } }

      it "should be valid" do
        expect(workflow).to be_valid
      end
    end
  end

  describe "#configuration" do
    let(:workflow) { build(:workflow, configuration: config ) }

    context "empty" do
      let(:config) { {} }

      it "should be valid" do
        expect(workflow).to be_valid
      end
    end

    context "with values" do
      let(:config) { { public_gold_standard: true } }

      it "should be valid" do
        expect(workflow).to be_valid
      end
    end
  end
end
