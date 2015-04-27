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

  describe "links" do
    let(:project) { create(:project) }
    let(:workflow) { create(:workflow, project: project) }

    it 'should allow links to workflows in the same project' do
      expect(SubjectSet).to link_to(workflow)
        .with_scope(:where, { project: project })
    end
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

    describe "#set_member_subjects_count" do
      let!(:add_subject) {
        create(:set_member_subject, subject_set: subject_set)
        subject_set.reload
      }

      it "should have a count of the number of set member subjects in the set" do
        expect(subject_set.set_member_subjects_count).to eq(subject_set.set_member_subjects.count)
      end
    end
  end

  describe "#retirement" do
    subject { build(:subject_set, retirement: retirement) }
    
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

  describe "#retirement_scheme" do
    subject { build(:subject_set, retirement: retirement) }

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

  describe "#retire_member?" do
    it "should call the scheme's retire? method" do
      scheme_double = double :retire? => true
      sms = build(:set_member_subject)
      allow(subject_set).to receive(:retirement_scheme).and_return(scheme_double)
      expect(scheme_double).to receive(:retire?).with(sms)
      subject_set.retire_member?(sms)
    end
  end
end
