require 'spec_helper'

RSpec.describe SubjectQueue, :type => :model do
  let(:locked_factory) { :subject_queue }
  let(:locked_update) { {set_member_subject_ids: [1, 2, 3, 4]} }

  it_behaves_like "optimistically locked"

  it 'should have a valid factory' do
    expect(build(:subject_queue)).to be_valid
  end

  it 'should not be valid with out a workflow' do
    expect(build(:subject_queue, workflow: nil)).to_not be_valid
  end

  describe "::create_for_user" do
    let(:workflow) {create(:workflow)}
    let(:user) { create(:user) }

    context "no logged out queue" do
      it 'should return nil' do
        expect(SubjectQueue.create_for_user(workflow, user)).to be_nil
      end
    end

    context "queue saves" do
      it 'should return the new queue' do
        create(:subject_queue, workflow: workflow, user: nil, subject_set: nil)
        expect(SubjectQueue.create_for_user(workflow, user)).to be_a(SubjectQueue)
      end
    end
  end

  describe "::reload" do
    let(:subject) { create(:set_member_subject) }
    let(:subjects) { create_list(:set_member_subject, 3).map(&:id) }
    let(:workflow) { create(:workflow) }

    context "when passed a subject set" do
      let(:subject_set) { create(:subject_set) }
      let(:not_updated_set) { create(:subject_set) }

      context "when the queue exists" do

        let!(:queue) do
          create(:subject_queue,
                 user: nil,
                 workflow: workflow,
                 set_member_subject_ids: [subject.id],
                 subject_set: subject_set)
        end

        let!(:not_updated_queue) do
          create(:subject_queue,
                 user: nil,
                 workflow: workflow,
                 set_member_subject_ids: [subject.id],
                 subject_set: not_updated_set)
        end

        before(:each) do
          SubjectQueue.reload(workflow, subjects, set: subject_set.id)
          queue.reload
          not_updated_queue.reload
        end

        it 'should completely replace the queue for the given set' do
          expect(queue.set_member_subject_ids).to eq(subjects)
        end

        it 'should not update the set without the name' do
          expect(not_updated_queue.set_member_subject_ids).to_not eq(subjects)
        end
      end

      context "when no queue exists" do
        before(:each) do
          SubjectQueue.reload(workflow, subjects, set: subject_set.id)
        end

        subject { SubjectQueue.find_by(workflow: workflow, subject_set: subject_set) }

        it 'should create a new queue with the given workflow' do
          expect(subject.workflow).to eq(workflow)
        end

        it 'should create a new queue with the given subject set' do
          expect(subject.subject_set).to eq(subject_set)
        end

         it 'should queue subject' do
          expect(subject.set_member_subject_ids).to eq(subjects)
        end
      end
    end

    context "when not passed a subject set" do
      context "when a queue exists" do
        let!(:queue) do
          create(:subject_queue,
                 user: nil,
                 workflow: workflow,
                 set_member_subject_ids: [subject.id])
        end

        it 'should reload the workflow queue' do
          SubjectQueue.reload(workflow, subjects)
          queue.reload
          expect(queue.set_member_subject_ids).to eq(subjects)
        end
      end

      context "when a queue does not exist" do
        before(:each) do
          SubjectQueue.reload(workflow, subjects)
        end

        subject { SubjectQueue.find_by(workflow: workflow) }

        it 'should create a new queue with the given workflow' do
          expect(subject.workflow).to eq(workflow)
        end

        it 'should queue subject' do
          expect(subject.set_member_subject_ids).to eq(subjects)
        end
      end
    end
  end

  describe "::dequeue_for_all" do
    let(:subject) { create(:set_member_subject) }
    let(:workflow) { create(:workflow) }
    let(:queue) { create_list(:subject_queue, 2, workflow: workflow, set_member_subject_ids: [subject.id]) }

    it "should remove the subject for all queues of the workflow" do
      SubjectQueue.dequeue_for_all(workflow, subject.id)
      expect(SubjectQueue.all.map(&:set_member_subject_ids)).to all( be_empty )
    end
  end

  describe "::enqueue_for_all" do
    let(:subject) { create(:set_member_subject) }
    let(:workflow) { create(:workflow) }
    let(:queue) { create_list(:subject_queue, 2, workflow: workflow) }

    it "should add the subject for all queues of the workflow" do
      SubjectQueue.enqueue_for_all(workflow, subject.id)
      expect(SubjectQueue.all.map(&:set_member_subject_ids)).to all( include(subject.id) )
    end
  end

  describe "::enqueue" do
    let(:workflow) { create(:workflow) }
    let(:subject) { create(:set_member_subject) }

    context "with a user" do
      let(:user) { create(:user) }
      context "nothing for user" do

        it 'should create a new user_enqueue_subject' do
          expect do
            SubjectQueue.enqueue(workflow,
                                 subject.id,
                                 user: user)
          end.to change{ SubjectQueue.count }.from(0).to(1)
        end

        it 'should add subjects' do
          SubjectQueue.enqueue(workflow, subject.id, user: user)
          queue = SubjectQueue.find_by(workflow: workflow, user: user)
          expect(queue.set_member_subject_ids).to include(subject.id)
        end

        context "passing an empty set of sms_ids", :focus do

          it 'should not raise an error' do
            expect {
              SubjectQueue.enqueue(workflow, [], user: user)
            }.to_not raise_error
          end

          it 'not attempt to find or create a queue' do
            expect(SubjectQueue).to_not receive(:find_or_create_by!)
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
      end

      context "list exists for user" do
        let!(:ues) { create(:subject_queue, user: user, workflow: workflow) }
        it 'should call add_subject_id on the existing subject queue' do
          SubjectQueue.enqueue(workflow,
                               subject.id,
                               user: user)
          expect(ues.reload.set_member_subject_ids).to include(subject.id)
        end
      end
    end
  end

  describe "::dequeue" do
    let(:workflow) { create(:workflow) }
    let(:subjects) { create_list(:set_member_subject, 2) }

    context "with a user" do
      let(:user) { create(:user) }
      it 'should remove the subject given a user and workflow' do
        ues = create(:subject_queue,
                     user: user,
                     workflow: workflow,
                     set_member_subject_ids: subjects.map(&:id))
        SubjectQueue.dequeue(workflow,
                             [subjects.first.id],
                             user: user)
        expect(ues.reload.set_member_subject_ids).to_not include(subjects.first.id)
      end
    end
  end

  describe "#next_subjects" do
    let(:ids) { (0..60).to_a }
    let(:ues) { build(:subject_queue, set_member_subject_ids: ids) }

    context "when the queue has a user" do
      it 'should return a collection of ids' do
        expect(ues.next_subjects).to all( be_a(Fixnum) )
      end

      it 'should return 10 by default' do
        expect(ues.next_subjects.length).to eq(10)
      end

      it 'should accept an optional limit argument' do
        expect(ues.next_subjects(20).length).to eq(20)
      end

      it 'should return the first subjects in the queue' do
        expect(ues.next_subjects).to match_array(ues.set_member_subject_ids[0..9])
      end
    end

    context "when the queue does not have a user" do
      let(:ues) { build(:subject_queue, set_member_subject_ids: ids, user: nil) }

      it 'should return a collection of ids' do
        expect(ues.next_subjects).to all( be_a(Fixnum) )
      end

      it 'should return 10 by default' do
        expect(ues.next_subjects.length).to eq(10)
      end

      it 'should accept an optional limit argument' do
        expect(ues.next_subjects(20).length).to eq(20)
      end

      it 'should randomly sample from the subject_ids' do
        expect(ues.next_subjects).to_not match_array(ues.set_member_subject_ids[0..9])
      end
    end
  end

  describe "#below_minimum?" do
    let(:queue) { build(:subject_queue, set_member_subject_ids: subject_ids) }

    context "when less than 20 items" do
      let(:subject_ids) { create_list(:set_member_subject, 2).map(&:id) }

      it 'should return true' do
        expect(queue.below_minimum?).to be true
      end
    end

    context "when more than 20 items" do
      let(:subject_ids) { create_list(:set_member_subject, 21).map(&:id) }

      it 'should return false' do
        expect(queue.below_minimum?).to be false
      end
    end
  end
end
