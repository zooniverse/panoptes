require "spec_helper"

RSpec.describe EmptySubjectQueueWorker do
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:user) { workflow.project.owner }
  let(:sms) do
    subject = create(:subject, project: workflow.project)
    create(:set_member_subject, subject: subject,
      subject_set: workflow.subject_sets.first)
  end
  let(:another_workflow) { create(:workflow) }
  let!(:queues) do
    [ workflow, another_workflow ].map do |w|
      create(:subject_queue, workflow: w, user: [user,nil].sample,
        set_member_subject_ids: [sms.id])
    end
  end

  subject { described_class.new }

  describe "#perform" do
    let(:queue_sms_ids) { queues.map(&:reload).map(&:set_member_subject_ids) }
    let(:empty_queues) { queue_sms_ids.map(&:empty?) }

    context "with no workflow id" do

      it 'should empty all the subject queues' do
        subject.perform
        expect(empty_queues).to all( be true )
      end
    end

    context "with a non-existant workflow id" do
      let(:w_id) { Workflow.last.id + 1 }

      it 'should not raise an error' do
        expect { subject.perform(w_id) }.not_to raise_error
      end

      it 'should not empty all subject queues' do
        subject.perform(w_id)
        expect(empty_queues).to all( be false )
      end
    end

    context "with a workflow id" do

      it 'should empty all the worfklow subject queues' do
        subject.perform(workflow.id)
        aggregate_failures "only workflow qs" do
          expect(empty_queues.first).to be true
          expect(empty_queues.last).to be false
        end
      end
    end
  end
end
