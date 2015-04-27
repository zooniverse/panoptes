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
    
    it "should remove the subject for all queues of the workflow" do
      SubjectQueue.enqueue_for_all(workflow, subject.id)
      expect(SubjectQueue.all.map(&:set_member_subject_ids)).to all( include(subject.id) )
    end
  end

  describe "::subjects_queued?" do
    let(:subject) { create(:set_member_subject) }
    let!(:subject_queue) do
      create(:subject_queue, set_member_subject_ids: [subject.id])
    end

    context "with a user" do
      context "subject is queued" do
        it 'should return truthy' do
          user = subject_queue.user
          workflow = subject_queue.workflow
          result = SubjectQueue.subjects_queued?(workflow,
                                                 [subject.id],
                                                 user: user)
          expect(result).to be_truthy
        end
      end

      context "subject is not queued" do
        it 'should return falsy' do
          user = subject_queue.user
          workflow = subject_queue.workflow
          result = SubjectQueue.subjects_queued?(workflow,
                                                 [create(:set_member_subject).id],
                                                 user: user)
          
          expect(result).to be_falsy
        end
      end

      context "queue doesn't exist" do
        it 'should return falsy' do
          user = create(:user)
          workflow = create(:workflow) 
          result = SubjectQueue.subjects_queued?(workflow,
                                                 [create(:set_member_subject).id],
                                                 user: user)
          expect(result).to be_falsy
        end
      end
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
                                 subject,
                                 user: user)
          end.to change{ SubjectQueue.count }.from(0).to(1)
        end

        it 'should add subjects' do
          SubjectQueue.enqueue(workflow,
                               subject,
                               user: user)
          queue = SubjectQueue.find_by(workflow: workflow, user: user)
          expect(queue.set_member_subject_ids).to include(subject.id)
        end
        
      end

      context "list exists for user" do
        let!(:ues) { create(:subject_queue, user: user, workflow: workflow) }
        it 'should call add_subject_id on the existing subject queue' do
          SubjectQueue.enqueue(workflow,
                               subject,
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

      it 'should destroy the model if there are no more set_member_subject_ids' do
        ues = create(:subject_queue,
                     user: user,
                     workflow: workflow,
                     set_member_subject_ids: [subjects.first.id])
        SubjectQueue.dequeue(workflow,
                             [subjects.first.id],
                             user: user)
        expect(SubjectQueue.exists?(ues)).to be_falsy
      end
    end
  end

  describe "#subjects" do
    let(:ids) { (0..60).to_a }
    let(:ues) { build(:subject_queue, set_member_subject_ids: ids) }
    
    it 'should return a collection of ids' do
      expect(ues.next_subjects).to all( be_a(Fixnum) )
    end

    it 'should return 10 by default' do
      expect(ues.next_subjects.length).to eq(10)
    end

    it 'should accept an optional limit argument' do
      expect(ues.next_subjects(20).length).to eq(20)
    end
  end

  describe "#add_set_member_subject" do
    let(:ues) { build(:subject_queue) }
    
    it 'should add the id to the set_member_subject_ids array' do
      subject = create(:subject)
      ues.add_set_member_subjects(subject)
      expect(ues.set_member_subject_ids).to include(subject.id)
    end
  end

  describe "#remove_set_member_subject" do
    let(:subject) { create(:subject) }
    let(:ues) { build(:subject_queue, set_member_subject_ids: [subject.id]) }
    
    it 'should remove the id from the subject ids' do
      ues.remove_set_member_subjects(subject)
      expect(ues.set_member_subject_ids).to_not include(subject.id)
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
