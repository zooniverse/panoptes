require "spec_helper"

RSpec.describe SubjectMetadataWorker do
  let(:user) { create :user }
  let(:project) { create :project_with_workflow, owner: user }
  let(:workflow) { project.workflows.first }
  let(:subject_one) do
    create(:subject, project: project, uploader: project.owner, metadata: {'#priority'=>1/3.0})
  end
  let(:subject_two) do
    create(:subject, project: project, uploader: project.owner, metadata: {'#priority'=>'2'})
  end
  let(:subject_set) do
    create(
      :subject_set_with_subjects,
      num_subjects: 1,
      project: project,
      workflows: [workflow],
      subjects: [subject_one, subject_two]
    )
  end
  let(:set_member_subject_ids) do
    subject_set.set_member_subject_ids
  end

  subject(:worker) { SubjectMetadataWorker.new }

  before do
    subject_set.subjects.reload
  end

  describe "#perform" do
    it 'skips any work when the feature flag is on' do
      Flipper.enable(:skip_subject_metadata_worker)
      allow(ActiveRecord::Base).to receive(:connection)
      worker.perform(subject_set.id)
      expect(ActiveRecord::Base).not_to have_received(:connection)
    end

    it 'copies priority from metadata to SMS attribute' do
      worker.perform(set_member_subject_ids)
      sms_one, sms_two, sms_three = SetMemberSubject.find(
        subject_set.set_member_subject_ids
      ).sort_by(&:id)
      expect(sms_one.priority).to eq(1/3.0)
      expect(sms_two.priority).to eq(2)
      expect(sms_three.priority).to be_nil
    end

    it 'raises not found if the SMS resources do not exist' do
      non_existant_ids = (1..3).to_a - set_member_subject_ids
      expect {
        worker.perform(non_existant_ids)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
