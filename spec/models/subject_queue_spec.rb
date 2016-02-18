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
    q = create(:subject_queue)
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

  describe "::by_user_workflow" do
    let(:workflow) { create(:workflow) }
    let(:user) { workflow.project.owner }
    let(:result) { SubjectQueue.by_user_workflow(user, workflow) }

    it "should not find any queue if none exist" do
      expect(result).to be_empty
    end

    it "should not find any queue if none exist for the user" do
      create(:subject_queue, workflow: workflow, subject_set: nil)
      expect(result).to be_empty
    end

    it "should not find the queue if none exists for the workflow" do
      create(:subject_queue, user: user, subject_set: nil)
      expect(result).to be_empty
    end

    it "should find the queue if it exists" do
      sq = create(:subject_queue, user: user, workflow: workflow, subject_set: nil)
      expect(result).to include(sq)
    end
  end

  describe "::below_minimum" do
    let(:sms_ids) { (1..11).to_a }
    let!(:above_minimum) { create(:subject_queue, set_member_subject_ids: sms_ids) }
    let!(:below_minimum) { create(:subject_queue, set_member_subject_ids: sms_ids[0..5]) }
    it 'should return all the queue with less than the minimum number of subjects' do
      expect(SubjectQueue.below_minimum).to include(below_minimum)
    end

    it 'should not return queue with more than minimum' do
      expect(SubjectQueue.below_minimum).to_not include(above_minimum)
    end
  end

  describe "::create_for_user" do
    let(:workflow) {create(:workflow)}
    let(:user) { create(:user) }

    context "when no logged out queue" do

      it 'should attempt to build a logged out queue' do
        expect(EnqueueSubjectQueueWorker).to receive(:perform_async).with(workflow.id, nil, nil)
        SubjectQueue.create_for_user(workflow, user)
      end

      it 'should return nil' do
        expect(SubjectQueue.create_for_user(workflow, user)).to be_nil
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
        expect(new_queue.set_member_subject_ids).to match_array(logged_out_queue.set_member_subject_ids)
      end
    end
  end

  describe "::reload" do
    let(:sms_id) { [1] }
    let(:smses) { (2..4).to_a }
    let(:workflow) { create(:workflow) }

    context "when passed a subject set" do
      let(:subject_set) { create(:subject_set) }
      let(:not_updated_set) { create(:subject_set) }

      context "when the queue exists" do
        let!(:queue) do
          create(:subject_queue,
                 user: nil,
                 workflow: workflow,
                 set_member_subject_ids: sms_id,
                 subject_set: subject_set)
        end
        let!(:not_updated_queue) do
          create(:subject_queue,
                 user: nil,
                 workflow: workflow,
                 set_member_subject_ids: sms_id,
                 subject_set: not_updated_set)
        end

        before(:each) do
          SubjectQueue.reload(workflow, smses, set_id: subject_set.id)
          queue.reload
          not_updated_queue.reload
        end

        it 'should completely replace the queue for the given set' do
          expect(queue.set_member_subject_ids).to match_array(smses)
        end

        it 'should not update the set without the name' do
          expect(not_updated_queue.set_member_subject_ids).to_not match_array(smses)
        end
      end

      context "when no queue exists" do
        before(:each) do
          SubjectQueue.reload(workflow, smses, set_id: subject_set.id)
        end

        subject { SubjectQueue.find_by(workflow: workflow, subject_set: subject_set) }

        it 'should create a new queue with the given workflow' do
          expect(subject.workflow).to eq(workflow)
        end

        it 'should create a new queue with the given subject set' do
          expect(subject.subject_set).to eq(subject_set)
        end

         it 'should queue subject' do
          expect(subject.set_member_subject_ids).to match_array(smses)
        end
      end
    end

    context "when not passed a subject set" do
      context "when a queue exists" do
        let!(:queue) do
          create(:subject_queue,
                 user: nil,
                 workflow: workflow,
                 set_member_subject_ids: sms_id)
        end

        it 'should reload the workflow queue' do
          SubjectQueue.reload(workflow, smses)
          queue.reload
          expect(queue.set_member_subject_ids).to eq(smses)
        end
      end

      context "when a queue does not exist" do
        before(:each) do
          SubjectQueue.reload(workflow, smses)
        end

        subject { SubjectQueue.find_by(workflow: workflow) }

        it 'should create a new queue with the given workflow' do
          expect(subject.workflow).to eq(workflow)
        end

        it 'should queue subject' do
          expect(subject.set_member_subject_ids).to eq(smses)
        end
      end
    end
  end

  describe "::dequeue_for_all" do
    let(:sms_id) { [1] }
    let(:workflow) { create(:workflow) }
    let(:queue) do
      create_list(:subject_queue, 2, workflow: workflow, set_member_subject_ids: sms_id)
    end

    it "should remove the subject for all queue of the workflow" do
      SubjectQueue.dequeue_for_all(workflow.id, sms_id)
      expect(SubjectQueue.all.map(&:set_member_subject_ids)).to all( be_empty )
    end
  end

  describe "::enqueue_for_all" do
    let(:sms_id) { [1] }
    let(:workflow) { create(:workflow) }
    let(:queue) { create_list(:subject_queue, 2, workflow: workflow) }

    it "should add the subject for all queue of the workflow" do
      SubjectQueue.enqueue_for_all(workflow.id, sms_id)
      expect(SubjectQueue.all.map(&:set_member_subject_ids)).to all( include(sms_id) )
    end
  end

  describe "::enqueue" do
    let(:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set, workflows: [workflow]) }
    let(:sms_id) { [1] }

    context "with a user" do
      let(:user) { create(:user) }
      context "nothing for user" do

        shared_examples "queue something" do
          it 'should create a new user_enqueue_subject' do
            expect do
              SubjectQueue.enqueue(workflow, ids, user: user)
            end.to change{ SubjectQueue.count }.from(0).to(1)
          end

          it 'should add subjects' do
            SubjectQueue.enqueue(workflow, ids, user: user)
            queue = SubjectQueue.find_by(workflow: workflow, user: user)
            expect(queue.set_member_subject_ids).to include(*ids)
          end
        end

        shared_examples "does not queue anything" do |arg|
          it 'should not raise an error' do
            expect {
              SubjectQueue.enqueue(workflow, [], user: user)
            }.to_not raise_error
          end

          it 'not attempt to find or create a queue'  do
            expect(SubjectQueue).to_not receive(:where)
            SubjectQueue.enqueue(workflow, [], user: user)
          end

          it 'should not call #enqueue_update' do
            expect_any_instance_of(SubjectQueue).to_not receive(:enqueue_update)
            SubjectQueue.enqueue(workflow, [], user: user)
          end

          it 'should return nil' do
            expect(SubjectQueue.enqueue(workflow, [], user: user)).to be_nil
          end
        end

        context "passing one sms_id" do
          let(:ids) { sms_id }

          it_behaves_like "queue something"
        end

        context "passing a set of sms_ids" do
          let(:ids) { (1..5).to_a }

          it_behaves_like "queue something"
        end

        context "passing an empty set of sms_ids" do
          it_behaves_like "does not queue anything", []
        end

        context "passing a set with one nil value" do
          it_behaves_like "does not queue anything", [nil]
        end
      end

      context "subject queue exists for user" do
        let(:sms) { create(:set_member_subject) }
        let(:smses) { create_list(:set_member_subject, 3, subject_set: sms.subject_set) }
        let(:sms_ids) { smses.map(&:id) }
        let!(:sq) do
          create(:subject_queue,
            set_member_subject_ids: sms_ids,
            user: user,
            workflow: workflow)
        end

        context "when the append queue contains a seen before" do
          before(:each) do
            create(:user_seen_subject, user: user, workflow: workflow, subject_ids: [sms.subject_id])
          end

          it "should not enqueue dups" do
            SubjectQueue.enqueue(workflow, sms.id, user: user)
            expect(sq.reload.set_member_subject_ids).to eq(smses.map(&:id))
          end
        end

        context "when the queue is below the enqueue threshold" do

          it 'should add the sms id to the existing subject queue' do
            allow_any_instance_of(SubjectQueue).to receive(:below_minimum?).and_return(true)
            SubjectQueue.enqueue(workflow, sms.id, user: user)
            expect(sq.reload.set_member_subject_ids).to include(sms.id)
          end
        end

        context "when the queue is above the enqueue threshold" do

          it 'should not have more than the limit in the existing subject queue' do
            sq.set_member_subject_ids = (0..22).to_a - [sms.id]
            sq.save!
            SubjectQueue.enqueue(workflow, sms.id, user: user)
            expect(sq.reload.set_member_subject_ids.length).to eq(20)
          end
        end

        it 'should not have a duplicate in the set' do
          expected_ids = sq.set_member_subject_ids | [ sms.id ]
          SubjectQueue.enqueue(workflow, sms.id, user: user)
          new_sms_ids = sq.reload.set_member_subject_ids
          expect(new_sms_ids).to match_array(expected_ids)
        end

        it 'should maintain the order of the set' do
          ordered_list = sq.set_member_subject_ids | [ sms.id ]
          SubjectQueue.enqueue(workflow, sms.id, user: user)
          expect(sq.reload.set_member_subject_ids).to eq(ordered_list)
        end

        context "when the queue is empty" do
          let(:sms_ids) { [] }

          it "should only enqueue the passed ids " do
            SubjectQueue.enqueue(workflow, sms.id, user: user)
            expect(sq.reload.set_member_subject_ids).to eq([ sms.id ])
          end
        end

        describe "duplicate id queueing" do
          let(:q_dups) do
            sq.set_member_subject_ids.sample(sq.set_member_subject_ids.size - 1)
          end
          let(:enq_ids_with_dups) { [ sms.id ] | q_dups }
          let(:fake_sms_ids) { double(blank?: false) }

          describe "non-modifying queue updates" do
            before do
              allow_any_instance_of(SeenSubjectRemover)
              .to receive(:ids_to_enqueue)
              .and_return(enqueue_set)
            end

            context "with an empty queue" do
              let(:enqueue_set) { [] }

              it "should not modify the queue" do
                expect{
                  SubjectQueue.enqueue(workflow, fake_sms_ids, user: user)
                }.not_to change{
                  sq.set_member_subject_ids
                }
              end
            end

            context "with the same ids" do
              let(:enqueue_set) { sq.set_member_subject_ids }

              it "should not modify the queue" do
                expect{
                  SubjectQueue.enqueue(workflow, fake_sms_ids, user: user)
                }.not_to change{
                  sq.set_member_subject_ids
                }
              end
            end
          end

          context "when the append queue has dups" do
            it "should not enqueue dups" do
              SubjectQueue.enqueue(workflow, enq_ids_with_dups, user: user)
              non_dups = sq.set_member_subject_ids | [ sms.id ]
              expect(sq.reload.set_member_subject_ids).to match_array(non_dups)
            end
          end

          context "when the append queue grows too large" do
            it "should only queue #{SubjectQueue::DEFAULT_LENGTH} ids" do
              start = smses.last.id+1
              append_ids = (start..start+SubjectQueue::DEFAULT_LENGTH*2).to_a
              SubjectQueue.enqueue(workflow, append_ids, user: user)
              expect(sq.reload.set_member_subject_ids.length)
                .to eq(SubjectQueue::DEFAULT_LENGTH)
            end
          end
        end
      end
    end
  end

  describe "::dequeue" do
    let(:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set, workflows: [workflow], project: workflow.project) }
    let(:sms) { create(:set_member_subject, subject_set: subject_set) }
    let(:smses) { create_list(:set_member_subject, 3, subject_set: sms.subject_set) }

    context "with a user" do
      let(:user) { create(:user) }
      let!(:sq) do
        create(:subject_queue, user: user, workflow: workflow, set_member_subject_ids: smses.map(&:id))
      end
      let(:sms_id_to_dequeue) { smses.sample.id }
      let(:dequeue_list) { [ sms_id_to_dequeue ] }

      it 'should remove the subject given a user and workflow' do
        SubjectQueue.dequeue(workflow, dequeue_list, user: user)
        sms_ids = sq.reload.set_member_subject_ids
        expect(sms_ids).to_not include(sms_id_to_dequeue)
      end

      it 'should maintain the order of the set' do
        ordered_list = sq.set_member_subject_ids.reject { |id| id == sms_id_to_dequeue }
        SubjectQueue.dequeue(workflow, dequeue_list, user: user)
        expect(sq.reload.set_member_subject_ids).to eq(ordered_list)
      end

      context "passing an empty set of sms_ids" do

        it 'should not raise an error' do
          expect {
            SubjectQueue.dequeue(workflow, [], user: user)
          }.to_not raise_error
        end

        it 'not attempt find the queue' do
          expect(SubjectQueue).to_not receive(:where)
          SubjectQueue.dequeue(workflow, [], user: user)
        end

        it 'should not call #dequeue_update' do
          expect_any_instance_of(SubjectQueue).to_not receive(:dequeue_update)
          SubjectQueue.dequeue(workflow, [], user: user)
        end

        it 'should return nil' do
          expect(SubjectQueue.dequeue(workflow, [], user: user)).to be_nil
        end
      end
    end
  end

  describe "#next_subjects" do
    let(:ids) { (0..60).to_a }
    let(:sq) { build(:subject_queue, set_member_subject_ids: ids) }

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
      let(:sq) { build(:subject_queue, set_member_subject_ids: ids, user: nil) }

      it_behaves_like "selects from the queue"
    end

    context "when the worklow is prioritized" do

      it "should select in order from the head of the queue" do
        allow_any_instance_of(Workflow).to receive(:prioritized).and_return(true)
        expect(sq.next_subjects).to match_array(sq.set_member_subject_ids[0..9])
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

    context "when more than #{SubjectQueue::MINIMUM_LENGTH} items" do
      let(:subject_ids) { (0..SubjectQueue::MINIMUM_LENGTH+1).to_a }

      it 'should return false' do
        expect(queue.below_minimum?).to be false
      end
    end
  end
end
