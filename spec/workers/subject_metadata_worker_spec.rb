require "spec_helper"

RSpec.describe SubjectMetadataWorker do
  let(:user) { create :user }
  let(:project) { create :project_with_workflow, owner: user }
  let(:workflow) { project.workflows.first }
  let(:subject_set) { create(:subject_set_with_subjects, project: project, workflows: [workflow]) }

  let!(:extra_subj) { create(:subject, project: subject_set.project) }
  let!(:extra_sms) { create(:set_member_subject, subject_set: subject_set, subject: extra_subj) }

  subject(:worker) { SubjectMetadataWorker.new }

  before do
    subject_set.subjects[0].metadata['#priority'] = 1
    subject_set.subjects[1].metadata['#priority'] = "2"
    subject_set.subjects.map(&:save)
  end

  describe "#perform" do
    it 'copies priority from metadata to SMS attribute' do
      worker.perform(subject_set.id)
      sms_one, sms_two, sms_three = SetMemberSubject.find(
        subject_set.set_member_subject_ids
      ).sort_by(&:id)
      expect(sms_one.priority).to eq(1)
      expect(sms_two.priority).to eq(2)
      expect(sms_three.priority).to be_nil
    end
  end
end