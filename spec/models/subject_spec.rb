require 'spec_helper'

describe Subject, :type => :model do
  let(:subject) { build(:subject) }
  let(:locked_factory) { :subject }
  let(:locked_update) { {metadata: { "Test" => "data" } } }

  it_behaves_like "optimistically locked"

  it "should have a valid factory" do
    expect(subject).to be_valid
  end

  describe "versioning" do
    let(:subject) { create(:subject) }

    it { is_expected.to be_versioned }

    it "should create versions when updated", versioning: true do
      expect do
        subject.update!(metadata: { more: "Meta" })
        subject.reload
      end.to change{subject.versions.length}.from(1).to(2)
    end

    it "should track metadata changes", versioning: true do
      new_meta = { more: "META" }
      subject.update!(metadata: new_meta)
      expect(subject.previous_version.metadata).to_not eq(new_meta)
    end

    it 'should not track other attribute changes', versioning: true do
      project = create(:project)
      subject.update!(project: project)
      expect(subject.previous_version).to be_nil
    end
  end

  it "should be invalid without a project_id" do
    subject.project = nil
    expect(subject).to_not be_valid
  end

  it "should be invalid without an upload_user_id" do
    subject.upload_user_id = nil
    expect(subject).to_not be_valid
  end

  describe "#collections" do
    let(:subject) { create(:subject, :with_collections) }

    it "should belong to many collections" do
      expect(subject.collections).to all( be_a(Collection) )
    end
  end

  describe "#subject_sets" do
    let(:subject) { create(:subject, :with_subject_sets) }

    it "should belong to many subject sets" do
      expect(subject.subject_sets).to all( be_a(SubjectSet) )
    end
  end

  describe "#set_member_subjects" do
    let(:set_member_subjects) { create(:subject, :with_subject_sets) }

    it "should have many set_member subjects" do
      expect(subject.set_member_subjects).to all( be_a(SetMemberSubject) )
    end
  end

  describe "#migrated_subject?" do

    it "should be falsy when the flag is not set" do
      expect(subject.migrated_subject?).to be_falsey
    end

    it "should be falsy when the flag is set to false" do
      subject.migrated = false
      expect(subject.migrated_subject?).to be_falsey
    end

    it "should be truthy when the flag is set true" do
      subject.migrated = true
      expect(subject.migrated_subject?).to be_truthy
    end
  end

  describe "#retired_for_workflow?" do
    let(:workflow) { create(:workflow) }
    let(:project) { workflow.project }
    let(:subject_set) { create(:subject_set, project: project, workflows: [workflow]) }
    let(:subject) { create(:subject, project: project) }
    let!(:set_member_subject) do
      create(:set_member_subject, subject_set: subject_set, subject: subject)
    end

    it "should be false when there is no associated SubjectWorkflowCount" do
      expect(subject.retired_for_workflow?(workflow)).to eq(false)
    end

    it "should be false with a non-persisted workflow" do
      expect(subject.retired_for_workflow?(Workflow.new)).to eq(false)
    end

    it "should be false when passing in any other type of instance" do
      expect(subject.retired_for_workflow?(SubjectSet.new)).to eq(false)
    end

    context "with a SubjectWorkflowCount" do
      let(:swc) { instance_double("SubjectWorkflowCount") }
      before(:each) do
        allow(SubjectWorkflowCount).to receive(:find_by).and_return(swc)
      end

      it "should be true when the swc is retired" do
        create(:subject_workflow_count, workflow: workflow, subject: subject, retired_at: DateTime.now)
        expect(subject.retired_for_workflow?(workflow)).to eq(true)
      end

      it "should be false when the sec is not retired" do
        allow(swc).to receive(:retired?).and_return(false)
        expect(subject.retired_for_workflow?(workflow)).to eq(false)
      end
    end
  end
end
