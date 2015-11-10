require 'spec_helper'

describe Workflow, :type => :model do
  let(:workflow) { build(:workflow) }
  let(:subject_relation) { create(:workflow_with_subjects) }
  let(:translatable) { create(:workflow_with_contents, build_extra_contents: true) }
  let(:translatable_without_content) { build(:workflow, build_contents: false) }
  let(:primary_language_factory) { :workflow }
  let(:locked_factory) { :workflow }
  let(:locked_update) { {display_name: "A Different Name"} }
  let(:cached_resource) { workflow }

  it_behaves_like "optimistically locked"
  it_behaves_like "has subject_count"
  it_behaves_like "is translatable"
  it_behaves_like "has an extended cache key", [:workflow_contents],
    [:subjects_count, :finished?]

  it "should have a valid factory" do
    expect(workflow).to be_valid
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
    create(:subject_workflow_count, workflow: workflow)
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

  describe "links" do
    let(:project) { create(:project) }
    let(:subject_set) { create(:subject_set, project: project) }

    it 'should allow links to subject_sets in the same project' do
      expect(Workflow).to link_to(subject_set)
        .with_scope(:where, { project: project })
    end
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

  describe "#classifcations_count" do
    let(:relation_instance) { workflow }

    it_behaves_like "it has a cached counter for classifications"
  end

  describe "versioning" do
    let(:workflow) { create(:workflow) }

    it { is_expected.to be_versioned }

    it 'should track changes to tasks', versioning: true do
      new_tasks = { blha: 'asdfasd', quera: "asdfas" }
      workflow.update!(tasks: new_tasks)
      expect(workflow.previous_version.tasks).to_not eq(new_tasks)
    end

    it 'should not track changes to primary_language', versioning: true do
      new_lang = 'en'
      workflow.update!(primary_language: new_lang)
      expect(workflow.previous_version).to be_nil
    end
  end

  describe "#retirement_scheme" do
    subject { build(:workflow, retirement: retirement) }

    context "empty" do
      let(:retirement) { Hash.new }

      it "it should return a classification count scheme" do
        expect(subject.retirement_scheme).to be_a(RetirementSchemes::ClassificationCount)
      end
    end

    context "classification_count" do
      let(:retirement) { { 'criteria' => 'classification_count' } }

      it "it should return a classification count scheme" do
        expect(subject.retirement_scheme).to be_a(RetirementSchemes::ClassificationCount)
      end
    end

    context "anything else" do
      let(:retirement) { { 'criteria' => 'anything else' } }

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
    end

    context "anything else" do
      let(:retirement) { { 'criteria' => 'anything else' } }

      it { is_expected.to_not be_valid }
    end
  end

  describe '#retire_subject' do
    let(:workflow) { create(:workflow_with_subject_sets) }
    let(:subject)  { create(:subject, subject_sets: workflow.subject_sets) }

    context 'when the subject has a workflow count' do
      it 'marks as retired' do
        create(:subject_workflow_count, subject: subject, workflow: workflow)
        workflow.retire_subject(subject.id)

        aggregate_failures do
          expect(subject.retired_for_workflow?(workflow)).to be_truthy
          expect(SubjectWorkflowCount.retired.count).to eq(1)
        end
      end
    end

    context 'when the subject does not have a workflow count' do
      it 'marks as retired' do
        workflow.retire_subject(subject.id)

        aggregate_failures do
          expect(subject.retired_for_workflow?(workflow)).to be_truthy
          expect(SubjectWorkflowCount.retired.count).to eq(1)
        end
      end
    end

    context 'when the subject is already retired' do
      it 'leaves the retirement timestamp as it was' do
        workflow.retire_subject(subject.id)
        retired_ats = SubjectWorkflowCount.order(:id).pluck(:retired_at)
        workflow.retire_subject(subject.id)

        aggregate_failures do
          expect(subject.retired_for_workflow?(workflow)).to be_truthy
          expect(SubjectWorkflowCount.retired.count).to eq(1)
          expect(SubjectWorkflowCount.order(:id).pluck(:retired_at)).to eq(retired_ats)
        end
      end
    end

    context 'when the subject does not belong to the workflow' do
      let(:subject) { create(:subject) }

      it 'does not retire' do
        workflow.retire_subject(subject.id)
        expect(SubjectWorkflowCount.count).to eq(0)
      end
    end
  end

  describe '#retired_subjects' do
    it 'returns through subject association' do
      sms = create(:set_member_subject)
      swc = create(:subject_workflow_count, subject: sms.subject, retired_at: Time.now)

      expect(swc.workflow.retired_subjects).to eq([sms.subject])
    end
  end

  describe "#retired_subjects_count" do
    it "should be an alias for retired set_member_subjects count" do
      expect(subject_relation.retired_subjects_count).to eq(subject_relation.retired_set_member_subjects_count)
    end
  end

  describe "#finished?" do
    it 'should be true when and retired count is equal or greater than the subject count ' do
      subject_relation.retired_set_member_subjects_count = subject_relation.subjects_count
      subject_relation.save!
      expect(subject_relation).to be_finished
    end

    context "when no subject_sets relation exist" do
      it 'should be false' do
        allow(workflow).to receive(:subjects_count).and_return(0)
        expect(workflow.finished?).to eq(false)
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

  describe "#config" do
    let(:workflow) { build(:workflow, config: config ) }

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
