require 'spec_helper'

describe Workflow, :type => :model do
  let(:workflow) { build(:workflow) }
  let(:subject_relation) { create(:workflow_with_subjects) }
  let(:translatable) { create(:workflow_with_contents, build_extra_contents: true) }
  let(:translatable_without_content) { build(:workflow, build_contents: false) }
  let(:primary_language_factory) { :workflow }
  let(:locked_factory) { :workflow }
  let(:locked_update) { {display_name: "A Different Name"} }

  it_behaves_like "optimistically locked"
  it_behaves_like "has subject_count"
  it_behaves_like "is translatable"

  it "should have a valid factory" do
    expect(workflow).to be_valid
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
  end
end
