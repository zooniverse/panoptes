require 'spec_helper'

RSpec.describe SubjectRetirementWorker do
  let(:worker) { described_class.new }

  let(:sms) { create(:set_member_subject) }
  let(:subject) { sms.subject }
  let(:workflow) { create(:workflow, subject_sets: [sms.subject_set]) }
  let!(:queue) { create(:subject_queue, workflow: workflow, set_member_subject_ids: [sms.id]) }


  describe "#perform" do
    context "when the workflow project is live" do
      before { workflow.project.update! live: true }

      it 'should retire the subject for the workflow' do
        worker.perform(subject.id, workflow.id)
        sms.reload
        expect(sms.retired_workflows).to include(workflow)
      end

      it "should increment the subject set's retirement count" do
        set2 = create(:subject_set)
        sms2 = create(:set_member_subject, subject: subject, subject_set: set2)
        workflow.subject_sets += [set2]
        workflow.save

        expect{ worker.perform(subject.id, workflow.id) }.to change{
          Workflow.find(workflow.id).retired_set_member_subjects_count
        }.from(0).to(2)
      end

      it "should dequeue all instances of the subject" do
        worker.perform(subject.id, workflow.id)
        queue.reload
        expect(queue.set_member_subject_ids).to_not include(sms.id)
      end
    end

    context "when the project is not live" do
      before { workflow.project.update! live: false }

      it 'does not mark the subject as retired' do
        worker.perform(subject.id, workflow.id)
        sms.reload
        expect(sms.retired_workflows).to_not include(workflow)
      end
    end
  end
end
