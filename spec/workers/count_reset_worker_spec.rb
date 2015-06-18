require "spec_helper"

RSpec.describe CountResetWorker do
  let(:workflows) { create_list(:workflow, 2, subject_sets: []) }
  let(:subject_set) { create(:subject_set, workflows: workflows) }
  let!(:sms) { create_list(:set_member_subject, 4, subject_set: subject_set, retired_workflows: [workflows.first]) }

  subject { CountResetWorker.new }

  describe "#perform" do
    it 'should reset the set_member_subject_count' do
      expect do
        SetMemberSubject.where(id: sms[0..1].map(&:id)).delete_all
        subject.perform(subject_set.id)
      end.to change{SubjectSet.find(subject_set.id).set_member_subjects_count}.from(4).to(2)
    end

    it 'should reset the workflow retired count' do
      workflow = workflows.first
      workflow.retired_set_member_subjects_count = SetMemberSubject.where("? = ANY(retired_workflow_ids)", workflow.id).count
      workflow.save!
      expect do
        SetMemberSubject.where(id: sms[0..1].map(&:id)).delete_all
        subject.perform(subject_set.id)
      end.to change{Workflow.find(workflow.id).retired_set_member_subjects_count}.from(4).to(2)
    end
  end

end
