require 'spec_helper'

RSpec.describe UserEnqueuedSubject, :type => :model do
  it 'should have a valid factory' do
    expect(build(:user_enqueued_subject)).to be_valid
  end

  it 'should not be valid with out a user' do
    expect(build(:user_enqueued_subject, user: nil)).to_not be_valid
  end

  it 'should not be valid with out a workflow' do
    expect(build(:user_enqueued_subject, workflow: nil)).to_not be_valid
  end

  describe "::enqueue_subject_for_user" do
    let(:user) { create(:user) }
    let(:workflow) { create(:workflow) }
    let(:subject) { create(:set_member_subject) }
    
    context "nothing for user" do
      it 'should create a new user_enqueue_subject' do
        expect do
          UserEnqueuedSubject.enqueue_subject_for_user(user: user,
                                                       workflow: workflow,
                                                       subject_id: subject.id)
        end.to change{ UserEnqueuedSubject.count }.from(0).to(1)
      end

      it 'should call add_subject_id' do
        ues = double
        allow(UserEnqueuedSubject).to receive(:find_or_create_by!).and_return(ues)
        
        expect(ues).to receive(:add_subject_id).with(subject.id)
        UserEnqueuedSubject.enqueue_subject_for_user(user: user,
                                                     workflow: workflow,
                                                     subject_id: subject.id)
      end
      
    end

    context "list exists for user" do
      let!(:ues) { create(:user_enqueued_subject, user: user, workflow: workflow) }
      it 'should call add_subject_id on the existing subject queue' do
        UserEnqueuedSubject.enqueue_subject_for_user(user: user,
                                                     workflow: workflow,
                                                     subject_id: subject.id)
        expect(ues.reload.subject_ids).to include(subject.id)
      end
    end
  end

  describe "::dequeue_subject_for_user" do
    let(:user) { create(:user) }
    let(:workflow) { create(:workflow) }
    let(:subjects) { create_list(:set_member_subject, 2) }
    
    it 'should remove the subject given a user and workflow' do
      ues = create(:user_enqueued_subject,
                   user: user,
                   workflow: workflow,
                   subject_ids: subjects.map(&:id))
      UserEnqueuedSubject.dequeue_subject_for_user(user: user,
                                                   workflow: workflow,
                                                   subject_id: subjects.first.id)
      expect(ues.reload.subject_ids).to_not include(subjects.first.id)
    end

    it 'should destroy the model if there are no more subject_ids' do
      ues = create(:user_enqueued_subject,
                   user: user,
                   workflow: workflow,
                   subject_ids: [subjects.first.id])
      UserEnqueuedSubject.dequeue_subject_for_user(user: user,
                                                   workflow: workflow,
                                                   subject_id: subjects.first.id)
      expect(UserEnqueuedSubject.exists?(ues)).to be_falsy

    end
  end

  describe "#sample_subjects" do
    let(:subjects) { create_list(:set_member_subject, 20) }
    let(:ues) { build(:user_enqueued_subject, subject_ids: subjects.map(&:id)) }
    
    it 'should return a collection of ids' do
      expect(ues.sample_subjects).to all( be_a(Fixnum) )
    end

    it 'should return 10 by default' do
      expect(ues.sample_subjects.length).to eq(10)
    end

    it 'should accept an optional limit argument' do
      expect(ues.sample_subjects(20).length).to eq(20)
    end
  end

  describe "#add_subject_id" do
    let(:ues) { build(:user_enqueued_subject) }
    
    it 'should add the id to the subject_ids array' do
      subject_id = create(:set_member_subject).id
      ues.add_subject_id(subject_id)
      expect(ues.subject_ids).to include(subject_id)
    end
  end

  describe "#remove_subject_id" do
    let(:subject) { create(:set_member_subject) }
    let(:ues) { build(:user_enqueued_subject, subject_ids: [subject.id]) }
    
    it 'should remove the id from the subject ids' do
      ues.remove_subject_id(subject.id)
      expect(ues.subject_ids).to_not include(subject.id)
    end
  end
end
