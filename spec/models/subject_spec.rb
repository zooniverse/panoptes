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
    let(:subject) { create(:subject_with_collections) }

    it "should belong to many collections" do
      expect(subject.collections).to all( be_a(Collection) )
    end
  end

  describe "#subject_sets" do
    let(:subject) { create(:subject_with_subject_sets) }

    it "should belong to many subject sets" do
      expect(subject.subject_sets).to all( be_a(SubjectSet) )
    end
  end

  describe "#set_member_subjects" do
    let(:set_member_subjects) { create(:subject_with_subject_sets) }

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

  describe "#uploader" do
    it "should have a counter cache" do
      subject.save!
      expect(subject.uploader.uploaded_subjects_count).to eq(1)
    end
  end

  describe "#retired_for_workflow?" do
    let(:workflow_id) { 5 }
    let(:workflow) { build(:workflow_with_subject_sets) }
    let!(:subject) { create(:subject_with_subject_sets) }

    before(:each) do
      allow(workflow).to receive(:persisted?).and_return(true)
      allow(workflow).to receive(:id).and_return(workflow_id)
      allow_any_instance_of(SubjectSet).to receive(:workflows).and_return([workflow])
    end

    it "should be false without a workflow" do
      expect(subject.retired_for_workflow?(workflow)).to eq(false)
    end

    it "should be false with a non-persisted workflow" do
      expect(subject.retired_for_workflow?(Workflow.new)).to eq(false)
    end

    it "should be false when passing in any other type of instace with and id" do
      expect(subject.retired_for_workflow?(SubjectSet.new)).to eq(false)
    end

    it "should be true when the retired_workflow_ids match" do
      allow_any_instance_of(SetMemberSubject).to receive(:retired_workflow_ids)
        .and_return([workflow.id])
      expect(subject.retired_for_workflow?(workflow)).to eq(true)
    end

    it "should be false without any matching retired_workflow_ids" do
      expect(subject.retired_for_workflow?(workflow)).to eq(false)
    end
  end
end
