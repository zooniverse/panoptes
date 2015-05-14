require 'spec_helper'

RSpec.describe QueueRemovalWorker do
  let(:workflows) { create_list(:workflow, 3) }
  let(:subject_sets) do
    [create(:subject_set_with_subjects, workflows: [workflows[0]]),
     create(:subject_set_with_subjects, workflows: workflows[1..2])]
  end

  let(:first_set_sms_ids) { subject_sets[0].set_member_subjects.pluck(:id) }
  let(:second_set_sms_ids) { subject_sets[1].set_member_subjects.pluck(:id) }

  let!(:queues) do
    [create(:subject_queue,
            workflow: workflows[0],
            user: nil,
            set_member_subject_ids: first_set_sms_ids),
     create(:subject_queue,
            workflow: workflows[0],
            set_member_subject_ids: first_set_sms_ids),
     create(:subject_queue,
            workflow: workflows[1],
            user: nil,
            set_member_subject_ids: second_set_sms_ids),
     create(:subject_queue,
            workflow: workflows[1],
            set_member_subject_ids: second_set_sms_ids),
          create(:subject_queue,
            workflow: workflows[1],
            user: nil,
            set_member_subject_ids: second_set_sms_ids),
     create(:subject_queue,
            workflow: workflows[1],
            set_member_subject_ids: second_set_sms_ids),
    ]
  end

  context "with one workflow" do
    it 'should dequeue all sms' do
      subject.perform(first_set_sms_ids, workflows.first.id)
      queues.each(&:reload)
      expect(queues[0..1].map(&:set_member_subject_ids)).to all( be_empty )
    end

    it 'should queue rebuilds' do
      expect(SubjectQueueWorker).to receive(:perform_async).exactly(2).times
      subject.perform(first_set_sms_ids, workflows.first.id)
    end
  end

  context "with multiple workflows" do
    it 'should dequeue all' do
      subject.perform(second_set_sms_ids, workflows[1..2].map(&:id))
      queues.each(&:reload)
      expect(queues[2..-1].map(&:set_member_subject_ids)).to all( be_empty )
    end

    it 'should queue rebuilds' do
      expect(SubjectQueueWorker).to receive(:perform_async).exactly(4).times
      subject.perform(second_set_sms_ids, workflows[1..2].map(&:id))
    end
  end
end
