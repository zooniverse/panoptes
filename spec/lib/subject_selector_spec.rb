require 'spec_helper'

RSpec.describe SubjectSelector do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:user) { ApiUser.new(create(:user)) }

  let!(:non_logged_in_queue) do
    create(:subject_queue,
           workflow: workflow,
           user: nil,
           subject_set: nil,
           set_member_subjects: create_list(:set_member_subject, 10))
  end

  subject { described_class.new(user, workflow, {}, Subject.all)}

  describe "#queued_subjects" do
    context "when the user doesn't have a queue" do
      before(:each) do
        subject.queued_subjects
      end

      it 'should create a new queue from the logged out queue' do
        expect(SubjectQueue.find_by(workflow: workflow, user: user.user)).to_not be_nil
      end

      it 'should add the logged out subjects to the new queue' do
        new_queue = SubjectQueue.find_by(workflow: workflow, user: user.user)
        expect(new_queue.set_member_subjects).to match_array(non_logged_in_queue.set_member_subjects)
      end
    end

    context "when the user doesn't have a queue" do
      it 'should raise an informative error' do
        allow_any_instance_of(Workflow).to receive(:subject_sets).and_return([])
        expect{subject.queued_subjects}.to raise_error(SubjectSelector::MissingSubjectSet,
          "no subject set is associated with this workflow")
      end
    end


    context "queue is empty" do
      let!(:non_logged_in_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: user.user,
               subject_set: nil,
               set_member_subjects: [])
      end

      let!(:subjects) { create_list(:set_member_subject, 10, subject_set: workflow.subject_sets.first) }

      it 'should return 5 subjects' do
        subjects, _ = subject.queued_subjects
        expect(subjects.length).to eq(5)
      end
    end

    it 'should return url_format: :get in the context object' do
      _, ctx = subject.queued_subjects
      expect(ctx).to include(url_format: :get)
    end
  end
end
