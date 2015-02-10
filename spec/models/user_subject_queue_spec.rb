require 'spec_helper'

RSpec.describe UserSubjectQueue, :type => :model do
  let(:locked_factory) { :user_subject_queue }
  let(:locked_update) { {subject_ids: [1, 2, 3, 4]} }
  
  it_behaves_like "optimistically locked"
  
  it 'should have a valid factory' do
    expect(build(:user_subject_queue)).to be_valid
  end

  it 'should not be valid with out a user' do
    expect(build(:user_subject_queue, user: nil)).to_not be_valid
  end

  it 'should not be valid with out a workflow' do
    expect(build(:user_subject_queue, workflow: nil)).to_not be_valid
  end

  describe "::are_subjects_queued" do
    let(:subject) { create(:subject) }
    let!(:subject_queue) do
      create(:user_subject_queue, subject_ids: [subject.id])
    end
    
    context "subject is queued" do
      it 'should return truthy' do
        user = subject_queue.user
        workflow = subject_queue.workflow
        result = UserSubjectQueue.are_subjects_queued?(user: user,
                                                       workflow: workflow,
                                                       subject_ids: [subject.id])
        expect(result).to be_truthy
      end

      context "subject is not queued" do
        it 'should return falsy' do
          user = subject_queue.user
          workflow = subject_queue.workflow
          result = UserSubjectQueue.are_subjects_queued?(user: user,
                                                         workflow: workflow,
                                                         subject_ids: [create(:subject).id])
          expect(result).to be_falsy
        end
      end

      context "queue doesn't exist" do
        it 'should return falsy' do
          user = create(:user)
          workflow = create(:workflow) 
          result = UserSubjectQueue.are_subjects_queued?(user: user,
                                                         workflow: workflow,
                                                         subject_ids: [create(:subject).id])
          expect(result).to be_falsy
        end

      end
    end
  end

  describe "::enqueue_subject_for_user" do
    let(:user) { create(:user) }
    let(:workflow) { create(:workflow) }
    let(:subject) { create(:subject) }
    
    context "nothing for user" do
      it 'should create a new user_enqueue_subject' do
        expect do
          UserSubjectQueue.enqueue_subject_for_user(user: user,
                                                    workflow: workflow,
                                                    subject: subject)
        end.to change{ UserSubjectQueue.count }.from(0).to(1)
      end

      it 'should call add_subjects' do
        ues = double
        allow(UserSubjectQueue).to receive(:find_or_create_by!).and_return(ues)
        
        expect(ues).to receive(:add_subjects).with(subject)
        UserSubjectQueue.enqueue_subject_for_user(user: user,
                                                  workflow: workflow,
                                                  subject: subject)
      end
      
    end

    context "list exists for user" do
      let!(:ues) { create(:user_subject_queue, user: user, workflow: workflow) }
      it 'should call add_subject_id on the existing subject queue' do
        UserSubjectQueue.enqueue_subject_for_user(user: user,
                                                  workflow: workflow,
                                                  subject: subject)
        expect(ues.reload.subject_ids).to include(subject.id)
      end
    end
  end

  describe "::dequeue_subjects_for_user" do
    let(:user) { create(:user) }
    let(:workflow) { create(:workflow) }
    let(:subjects) { create_list(:subject, 2) }
    
    it 'should remove the subject given a user and workflow' do
      ues = create(:user_subject_queue,
                   user: user,
                   workflow: workflow,
                   subject_ids: subjects.map(&:id))
      UserSubjectQueue.dequeue_subjects_for_user(user: user,
                                                 workflow: workflow,
                                                 subject_ids: [subjects.first.id])
      expect(ues.reload.subject_ids).to_not include(subjects.first.id)
    end

    it 'should destroy the model if there are no more subject_ids' do
      ues = create(:user_subject_queue,
                   user: user,
                   workflow: workflow,
                   subject_ids: [subjects.first.id])
      UserSubjectQueue.dequeue_subjects_for_user(user: user,
                                                 workflow: workflow,
                                                 subject_ids: [subjects.first.id])
      expect(UserSubjectQueue.exists?(ues)).to be_falsy

    end
  end

  describe "#next_subjects" do
    let(:ids) { (0..60).to_a }
    let(:ues) { build(:user_subject_queue, subject_ids: ids) }
    
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

  describe "#add_subject" do
    let(:ues) { build(:user_subject_queue) }
    
    it 'should add the id to the subject_ids array' do
      subject = create(:subject)
      ues.add_subjects(subject)
      expect(ues.subject_ids).to include(subject.id)
    end
  end

  describe "#remove_subject" do
    let(:subject) { create(:subject) }
    let(:ues) { build(:user_subject_queue, subject_ids: [subject.id]) }
    
    it 'should remove the id from the subject ids' do
      ues.remove_subjects(subject)
      expect(ues.subject_ids).to_not include(subject.id)
    end
  end
end
