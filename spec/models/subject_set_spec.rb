require 'spec_helper'

describe SubjectSet, :type => :model do
  let(:subject_set) { create(:subject_set) }
  let(:locked_factory) { :subject_set }
  let(:locked_update) { {display_name: "A Different Name"} }

  it_behaves_like "optimistically locked"

  it "should have a valid factory" do
    expect(build(:subject_set)).to be_valid
  end

  it "display_names should be unqiue within a project" do
    s = create(:subject_set)
    expect(build(:subject_set, project: s.project, display_name: s.display_name)).to_not be_valid
  end

  it "should only have a workflow assigned once" do
    w = create(:workflow)
    subject_set.workflows << w
    subject_set.save!
    expect do
      subject_set.workflows << w
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  describe "#project" do
    it "should have a project" do
      expect(subject_set.project).to be_a(Project)
    end

    it "should not be valid without a project" do
      expect(build(:subject_set, project: nil)).to_not be_valid
    end
  end

  describe "#workflows" do
    it "should have many workflows" do
      expect(subject_set.workflows).to all( be_a(Workflow) )
    end
  end

  describe "#subjects" do
    let(:subject_set) { create(:subject_set_with_subjects) }

    it "should have many subjects" do
      expect(subject_set.subjects).to all( be_a(Subject) )
    end
  end

  context "set with member subjects" do
    let(:subject_set) { create(:subject_set_with_subjects) }

    describe "#set_member_subjects" do
      it "should have many seted subjects" do
        expect(subject_set.set_member_subjects).to all( be_a(SetMemberSubject) )
      end
    end

    describe "#set_member_subjects_count", :disabled do
      let!(:add_subject) {
        create(:set_member_subject, subject_set: subject_set)
        subject_set.reload
      }

      it "should have a count of the number of set member subjects in the set" do
        expect(subject_set.set_member_subjects_count).to eq(subject_set.set_member_subjects.count)
      end
    end
  end

  describe "#belongs_to_project?" do
    it "should be false with nil" do
      expect(subject_set.belongs_to_project?(nil)).to eq(false)
    end

    it "should be false with it's another project id" do
      expect(subject_set.belongs_to_project?(subject_set.project_id+1)).to eq(false)
    end

    it "should be true with it's own project id" do
      expect(subject_set.belongs_to_project?(subject_set.project_id)).to eq(true)
    end
  end

  describe '#subject_set_imports' do
    let(:subject_set_import) do
      create(:subject_set_import, subject_set: subject_set)
    end

    it 'removes all subject_set_imports on destroy' do
      subject_set_import
      subject_set.destroy
      expect { subject_set_import.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
