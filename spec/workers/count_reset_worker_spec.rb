require "spec_helper"

RSpec.describe CountResetWorker do
  let(:workflows) { create_list(:workflow, 2, subject_sets: []) }
  let(:subject_set) { create(:subject_set, workflows: workflows) }
  let!(:sms) { create_list(:set_member_subject, 4, subject_set: subject_set) }

  subject(:worker) { CountResetWorker.new }

  describe "#perform" do
    it 'should reset the workflow retired count' do
      workflow = workflows.first
      workflow.update! retired_set_member_subjects_count: 100

      sms.take(2).each do |s|
        opts = { set_member_subject: s, workflow: workflow, retired_at: Time.now, link_subject_sets: false}
        create(:subject_workflow_count, opts)
      end

      expect do
        worker.perform(subject_set.id)
      end.to change{Workflow.find(workflow.id).retired_set_member_subjects_count}.from(100).to(2)
    end

    context "when the subject_set by id can't be found" do
      it "should stop and not update the workflow retired sms counts" do
        subject_set_id = subject_set.id
        subject_set.destroy
        expect_any_instance_of(Workflow).to_not receive(:save!)
        subject.perform(subject_set_id)
      end
    end
  end
end
