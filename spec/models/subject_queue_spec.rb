require 'spec_helper'

RSpec.describe SubjectQueue, type: :model do
  let(:locked_factory) { :subject_queue }
  let(:locked_update) { {set_member_subject_ids: [1, 2, 3, 4]} }

  it_behaves_like "optimistically locked"

  it 'should have a valid factory' do
    expect(build(:subject_queue)).to be_valid
  end

  it 'should not be valid with out a workflow' do
    expect(build(:subject_queue, workflow: nil)).to_not be_valid
  end

  it 'should not be valid unless its is unique for the set, workflow, and user' do
    q = create(:subject_queue)
    expect(build(:subject_queue, subject_set: q.subject_set, workflow: q.workflow, user: q.user)).to_not be_valid
  end

  it 'should be valid if the subject set is different but the workflow and user are the same' do
    set = create(:subject_set)
    q = create(:subject_queue, subject_set: set)
    expect(build(:subject_queue, workflow: q.workflow, user: q.user)).to be_valid
  end

  describe "::by_set" do
    let(:workflow) { create(:workflow_with_subject_set) }
    let(:user) { workflow.project.owner }
    let(:set) { workflow.subject_sets.first }
    let(:set_id) { set.id }
    let(:result) { SubjectQueue.by_set(set_id) }

    it "should not find any queue if none exist" do
      expect(result).to be_empty
    end

    it "should not find the queue if none exists for the subject_set" do
      create(:subject_queue, user: user, workflow: workflow, subject_set: nil)
      expect(result).to be_empty
    end

    context "when searching without a set id" do
      let(:set_id) { nil }

      it "should find all queues" do
        sq = create(:subject_queue, user: user, workflow: workflow, subject_set: set)
        expect(result).to include(sq)
      end
    end

    it "should find the queue if it exists for the subject set" do
      sq = create(:subject_queue, user: user, workflow: workflow, subject_set: set)
      expect(result).to include(sq)
    end
  end

  describe "::create_for_user" do
    let(:workflow) { create(:workflow) }
    let(:user) { workflow.project.owner }

    context "when no logged out queue" do

      it 'should create a logged out queue and schedule a fill on it' do
        expect(SubjectQueue)
          .to receive(:create!)
          .with(workflow: workflow, user: nil, subject_set_id: nil)
          .and_call_original
        expect(EnqueueSubjectQueueWorker).to receive(:perform_async)
        SubjectQueue.create_for_user(workflow, user)
      end

      it 'should return the persisted queue', :aggregate_failures do
        queue = SubjectQueue.create_for_user(workflow, user)
        expect(queue).to be_a(SubjectQueue)
        expect(queue.persisted?).to be true
      end
    end

    context "queue saves" do
      let!(:logged_out_queue) do
        create(:subject_queue, workflow: workflow, user: nil, subject_set: nil)
      end
      let(:new_queue) { SubjectQueue.create_for_user(workflow, user)}

      it 'should return the new queue' do
        aggregate_failures "copied queue" do
          expect(new_queue).to be_a(SubjectQueue)
          expect(new_queue.id).to_not eq(logged_out_queue.id)
        end
      end

      it 'should add the logged out subjects to the new queue' do
        expect(new_queue.set_member_subject_ids)
          .to match_array(logged_out_queue.set_member_subject_ids)
      end
    end
  end

  describe "#update_ids" do
    let(:ids) { (5..10).to_a }
    let(:sq) do
      create(:subject_queue, subject_set: nil, set_member_subject_ids: ids)
    end

    it "should replace the queue ids when passed an empty list" do
      sq.update_ids([])
      expect(sq.reload.set_member_subject_ids).to be_empty
    end

    it "should replace the queue ids when passed nil" do
      sq.update_ids(nil)
      expect(sq.reload.set_member_subject_ids).to be_empty
    end

    it "should replace to the queue when given ids" do
      sq.update_ids(1)
      expect(sq.reload.set_member_subject_ids).to eq([1])
    end

    it "should touch the updated_at timestamp if the attribute changes" do
      expect {
        sq.update_ids(1)
      }.to change{ sq.updated_at }
    end
  end

  describe "#enqueue_update" do
    let(:ids) { (5..10).to_a }
    let(:sq) do
      create(:subject_queue, subject_set: nil, set_member_subject_ids: ids)
    end

    it "should not modify the queue when given no ids" do
      expect { sq.enqueue_update([]) }.not_to change { sq.set_member_subject_ids }
    end

    it "should append to the queue when given ids" do
      sq.enqueue_update(1)
      expect(sq.reload.set_member_subject_ids).to eq(ids | [1])
    end
  end

  describe "#dequeue_update" do
    let(:ids) { (5..10).to_a }
    let(:sq) do
      create(:subject_queue, subject_set: nil, set_member_subject_ids: ids)
    end

    it "should not modify the queue when given no ids" do
      expect { sq.dequeue_update([]) }.not_to change { sq.set_member_subject_ids }
    end

    it "should remove from the queue when given ids" do
      sq.dequeue_update(6)
      expect(sq.reload.set_member_subject_ids).to eq(ids - [6])
    end
  end

  describe "#next_subjects" do
    let(:ids) { (0..20).to_a }
    let(:sq) do
      create(:subject_queue, set_member_subject_ids: ids)
    end

    shared_examples "selects from the queue" do
      it 'should return a collection of ids' do
        expect(sq.next_subjects).to all( be_a(Fixnum) )
      end

      it 'should return 10 by default' do
        expect(sq.next_subjects.length).to eq(10)
      end

      it 'should accept an optional limit argument' do
        expect(sq.next_subjects(20).length).to eq(20)
      end

      it 'should randomly sample from the subject_ids' do
        expect(sq.next_subjects).to_not match_array(sq.set_member_subject_ids[0..9])
      end
    end

    context "when the queue has a user" do

      it_behaves_like "selects from the queue"
    end

    context "when the queue does not have a user" do
      let(:sq) do
        create(:subject_queue, user: nil, set_member_subject_ids: ids)
      end

      it_behaves_like "selects from the queue"
    end

    context "when the worklow is prioritized" do

      it "should select in order from the head of the queue" do
        allow_any_instance_of(Workflow).to receive(:prioritized).and_return(true)
        expected = sq.set_member_subject_ids[0..9]
        expect(sq.next_subjects).to match_array(expected)
      end
    end
  end

  describe "#below_minimum?" do
    let(:queue) { build(:subject_queue, set_member_subject_ids: subject_ids) }

    context "when less than #{SubjectQueue::MINIMUM_LENGTH} items" do
      let(:subject_ids) { [1, 2] }

      it 'should return true' do
        expect(queue.below_minimum?).to be true
      end
    end

    context "when equal to #{SubjectQueue::MINIMUM_LENGTH} items" do
      let(:subject_ids) { (1..SubjectQueue::MINIMUM_LENGTH).to_a }

      it 'should return true' do
        expect(queue.below_minimum?).to be true
      end
    end

    context "when more than #{SubjectQueue::MINIMUM_LENGTH} items" do
      let(:subject_ids) { (0..SubjectQueue::MINIMUM_LENGTH).to_a }

      it 'should return false' do
        expect(queue.below_minimum?).to be false
      end
    end
  end

  describe "#stale?" do
    let(:queue) { build(:subject_queue, set_member_subject_ids: []) }

    it "should be false if the object is not persisted" do
      expect(queue.stale?).to be false
    end

    it "should not be stale when last updated less than time threshold" do
      allow(queue).to receive(:updated_at).and_return(Time.zone.now)
      expect(queue.stale?).to be false
    end

    it "should be stale when last updated greater than time threshold" do
      allow(queue).to receive(:updated_at).and_return(Time.zone.now-30.minutes)
      expect(queue.stale?).to be true
    end
  end
end
