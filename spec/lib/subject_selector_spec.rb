require 'spec_helper'

RSpec.describe SubjectSelector do
  let(:workflow) { create(:workflow) }
  let(:user) { ApiUser.new(create(:user)) }
  describe "#queued_subjects" do
    subject { described_class.new(user, workflow, {}, Subject.all)}
    context "when the user doesn't have a queue" do
      let!(:queue) do
        create(:subject_queue,
               workflow: workflow,
               user: nil,
               subject_set: nil,
               set_member_subjects: create_list(:set_member_subject, 10))
      end

      before(:each) do
        subject.queued_subjects
      end

      it 'should create a new queue from the logged out queue' do
        expect(SubjectQueue.find_by(workflow: workflow, user: user.user)).to_not be_nil
      end

      it 'should add the logged out subjects to the new queue' do
        new_queue = SubjectQueue.find_by(workflow: workflow, user: user.user)
        expect(new_queue.set_member_subjects).to match_array(queue.set_member_subjects)
      end
    end
  end
end
