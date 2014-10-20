require 'spec_helper'

describe Subject, :type => :model do

  let(:subject) { build(:subject) }

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

    it "should track location changes", versioning: true do
      new_loc = { standard: "http://test.host/img.jpg.gif" }
      subject.update!(locations: new_loc)
      expect(subject.previous_version.locations).to_not eq(new_loc)
    end

    it "should track metadata changes", versioning: true do
      new_meta = { more: "META" }
      subject.update!(metadata: new_meta)
      expect(subject.previous_version.metadata).to_not eq(new_meta)
    end

    it 'should not track other attribute changes', versioning: true do
      new_owner = create(:user)
      subject.update!(owner: new_owner)
      expect(subject.previous_version).to be_nil
    end
  end

  it "should be invalid without a project_id" do
    subject.project = nil
    expect(subject).to_not be_valid
  end

  it "should be invalid without an owner_id" do
    subject.owner = nil
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
end
