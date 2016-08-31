require "spec_helper"

RSpec.describe WorkflowRetiredCountWorker do
  let(:workflows) { create_list(:workflow, 2, subject_sets: []) }
  let(:subject_set) { create(:subject_set, workflows: workflows) }
  let(:sms) { create_list(:set_member_subject, 4, subject_set: subject_set) }

  subject(:worker) { WorkflowRetiredCountWorker.new }

  describe "#perform" do
    let(:workflow) { workflows.first }
    let(:non_retired_swc) do
      create(:subject_workflow_status, subject: sms.last.subject, workflow: workflow, link_subject_sets: false)
    end
    before do
      workflow.update! retired_set_member_subjects_count: 100
      sms.take(2).each do |s|
        opts = { subject: s.subject, workflow: workflow, retired_at: Time.now, link_subject_sets: false}
        create(:subject_workflow_status, opts)
      end
    end

    it 'should reset the workflow retired count' do
      non_retired_swc
      expect do
        worker.perform(workflow.id)
      end.to change{Workflow.find(workflow.id).retired_set_member_subjects_count}.from(100).to(2)
    end

    it 'should respect the project launch date' do
      workflow.project.update_column(:launch_date, DateTime.now)
      expect do
        worker.perform(workflow.id)
      end.to change{Workflow.find(workflow.id).retired_set_member_subjects_count}.from(100).to(0)
    end
  end
end
