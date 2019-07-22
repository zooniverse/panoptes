require 'spec_helper'

describe Subject, :type => :model do
  let(:subject) { build(:subject) }
  let(:locked_factory) { :subject }
  let(:locked_update) { {metadata: { "Test" => "data" } } }

  it_behaves_like "optimistically locked"

  it "should have a valid factory" do
    expect(subject).to be_valid
  end

  it "should by default be active" do
    expect(subject.active?).to be_truthy
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
    let(:subject) { create(:subject, :with_subject_sets) }

    it "should have many set_member subjects" do
      expect(subject.set_member_subjects).to all( be_a(SetMemberSubject) )
    end
  end

  describe "#workflows" do
    let(:subject) { create(:subject, :with_subject_sets) }

    it "should have many set_member subjects" do
      expect(subject.workflows).to all( be_a(Workflow) )
    end
  end

  describe "ordered_locations" do
    it_behaves_like "it has ordered locations" do
      let(:resource) do
        create(:subject, :with_mediums, :with_subject_sets, num_sets: 1)
      end
      let(:klass) { Subject }
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

    it "should be false when there is no associated SubjectWorkflowStatus" do
      expect(subject.retired_for_workflow?(workflow)).to eq(false)
    end

    it "should be false with a non-persisted workflow" do
      expect(subject.retired_for_workflow?(Workflow.new)).to eq(false)
    end

    it "should be false when passing in any other type of instance" do
      expect(subject.retired_for_workflow?(SubjectSet.new)).to eq(false)
    end

    context "with a SubjectWorkflowStatus" do
      let(:swc) { instance_double("SubjectWorkflowStatus") }
      before(:each) do
        allow(SubjectWorkflowStatus).to receive(:find_by).and_return(swc)
      end

      it "should be true when the swc is retired" do
        create(:subject_workflow_status, workflow: workflow, subject: subject, retired_at: DateTime.now)
        expect(subject.retired_for_workflow?(workflow)).to eq(true)
      end

      it "should be false when the sec is not retired" do
        allow(swc).to receive(:retired?).and_return(false)
        expect(subject.retired_for_workflow?(workflow)).to eq(false)
      end
    end
  end

  describe '.location_attributes_from_params' do
    context 'when given a string' do
      it 'sets content type when an element is a string' do
        results = Subject.location_attributes_from_params(['image/jpeg'])
        expect(results).to eq([{content_type: "image/jpeg", metadata: {index: 0}}])
      end

      it 'converts non-standard mimetypes' do
        results = Subject.location_attributes_from_params(['audio/mp3'])
        expect(results).to eq([{content_type: 'audio/mpeg', metadata: {index: 0}}])
      end
    end

    context 'when given a hash' do
      it 'generates an external location' do
        results = Subject.location_attributes_from_params([{"image/jpeg" => "https://example.org/kittens.jpg"}])
        expect(results).to eq([{content_type: 'image/jpeg',
                                external_link: true,
                                src: "https://example.org/kittens.jpg",
                                metadata: {index: 0}}])
      end

      it 'converts non-standard mimetypes' do
        results = Subject.location_attributes_from_params([{"audio/mp3" => "https://example.org/kittens.mp3"}])
        expect(results).to eq([{content_type: 'audio/mpeg',
                                external_link: true,
                                src: "https://example.org/kittens.mp3",
                                metadata: {index: 0}}])
      end
    end

    describe '#surrounding' do
      let(:workflow) { create(:workflow) }
      let(:subject_set) { create(:subject_set, project: workflow.project) }
      let(:smses) { create_list(:set_member_subject, 21, subject_set: subject_set) }
      let(:test_sms) { smses[smses.length/2] }

      it 'uses the default gap, default window' do
        result = test_sms.subject.surrounding(subject_set.id)

        # Map across smses for subject ids to avoid testing metadata hash order
        expect(result.map{|x| x.id}).to eq( smses[5..15].map{|x| x.subject.id} )
      end

      it 'uses the defined gap and window' do
        result = test_sms.subject.surrounding(subject_set.id, 3, 2)

        expect(result.map{|x| x.id})
          .to eq( smses.values_at(4, 6, 8, 10, 12, 14, 16)
          .map{|x| x.subject.id} )
      end

      it 'includes nils if surrounding index is out of range' do
        result = test_sms.subject.surrounding(subject_set.id, 3, 4)

        expect(result.map{|x| x&.id}).to eq(
          smses.values_at(2, 6, 10, 14, 18)
               .map{|x| x.subject.id}
               .push(nil)
               .unshift(nil)
        )
      end

    end
  end
end
