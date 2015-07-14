require 'spec_helper'

RSpec.describe SubjectLifecycle do
  let(:sms) { create(:set_member_subject) }
  let(:subject) { sms.subject }
  let(:workflow) { create(:workflow, subject_sets: [sms.subject_set]) }
  let!(:queue) { create(:subject_queue, workflow: workflow, set_member_subject_ids: [sms.id]) }

  let(:lifecycle) { described_class.new(subject) }

  describe "#retire_for" do
    it 'should retire the subject for the workflow' do
      lifecycle.retire_for(workflow)
      sms.reload
      expect(sms.retired_workflows).to include(workflow)
    end

    it "should increment the workflow retired subjects counter" do
      set2 = create(:subject_set)
      sms2 = create(:set_member_subject, subject: subject, subject_set: set2)
      workflow.subject_sets += [set2]
      workflow.save

      expect{ lifecycle.retire_for(workflow) }.to change{
        Workflow.find(workflow.id).retired_set_member_subjects_count
      }.from(0).to(2)
    end

    it "should dequeue all instances of the subject" do
      lifecycle.retire_for(workflow)
      queue.reload
      expect(queue.set_member_subject_ids).to_not include(sms.id)
    end
  end
end
