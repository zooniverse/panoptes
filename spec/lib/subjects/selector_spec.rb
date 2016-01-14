require 'spec_helper'

RSpec.describe Subjects::Selector do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:user) { ApiUser.new(create(:user)) }
  let(:smses) { create_list(:set_member_subject, 10).reverse }
  let(:params) { {} }
  let(:subject_queue) do
    create(:subject_queue,
           workflow: workflow,
           user: nil,
           subject_set: nil,
           set_member_subjects: smses)
  end

  subject { described_class.new(user, workflow, params, Subject.all)}

  describe "#queued_subjects" do
    it 'should return url_format: :get in the context object' do
      subject_queue
      _, ctx = subject.queued_subjects
      expect(ctx).to include(url_format: :get)
    end

    context "when the user doesn't have a queue" do

      it 'should create a new queue from the logged out queue' do
        subject_queue
        expect(SubjectQueue).to receive(:create_for_user)
          .with(workflow, user.user, set_id: nil).and_call_original
        subject.queued_subjects
      end

      context "when the workflow doesn't have any subject sets" do

        it 'should raise an informative error' do
          allow_any_instance_of(Workflow).to receive(:subject_sets).and_return([])
          expect{subject.queued_subjects}.to raise_error(Subjects::Selector::MissingSubjectSet,
            "no subject set is associated with this workflow")
        end
      end

      context "when the subject sets have no data" do

        it 'should raise the an error' do
          allow_any_instance_of(Workflow)
            .to receive(:set_member_subjects).and_return([])
          message = "No data available for selection"
          expect {
            subject.queued_subjects
          }.to raise_error(Subjects::Selector::MissingSubjects, message)
        end
      end
    end

    context "when the params page size is set as a string" do
      let(:size) { 2 }
      subject do
        params = { page_size: "#{size}" }
        described_class.new(user, workflow, params, Subject.all)
      end

      it 'should return the page_size number of subjects' do
        subject_queue
        subjects, _context = subject.queued_subjects
        expect(subjects.length).to eq(size)
      end
    end

    context "queue is empty" do
      let(:subject_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: user.user,
               subject_set: queue_subject_set,
               set_member_subjects: [])
      end
      let(:subject_set) { workflow.subject_sets.first }
      let(:queue_subject_set) { nil }

      before do
        create_list(:set_member_subject, 10, subject_set: subject_set)
        subject_queue
      end

      it 'should return 5 subjects' do
        subjects, _ = subject.queued_subjects
        expect(subjects.length).to eq(5)
      end

      context "when the database selection strategy returns an empty set" do
        let(:queue_subject_set) { subject_set }

        before do
          allow_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select).and_return([])
          expect_any_instance_of(Subjects::PostgresqlSelection)
            .to receive(:any_workflow_data)
            .and_call_original
        end

        it 'should fallback to selecting some data' do
          subjects, _context = subject.queued_subjects
        end

        context "and the workflow is grouped" do
          let(:subject_set_id) { subject_set.id }
          let(:params) { { subject_set_id: subject_set_id } }

          it 'should fallback to selecting some grouped data' do
            allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
            subjects, _context = subject.queued_subjects
          end
        end
      end
    end

    describe "#dequeue after selection" do
      let(:smses) { workflow.set_member_subjects }
      let(:sms_ids) { smses.map(&:id) }
      let(:subject_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: queue_owner,
               subject_set: nil,
               set_member_subjects: smses)
      end

      before(:each) { subject_queue }

      context "when the user has a queue" do
        let(:queue_owner) { user.user }

        it 'should call dequeue_subject for the user' do
          expect(DequeueSubjectQueueWorker).to receive(:perform_async)
            .with(workflow.id, array_including(sms_ids), queue_owner.id, nil)
          subject.queued_subjects
        end
      end

      context "when the queue has no user" do
        let(:queue_owner) { nil }
        let(:user) { ApiUser.new(nil) }

        it 'should not call dequeue_subject for the user' do
          expect(DequeueSubjectQueueWorker).to_not receive(:perform_async)
          subject.queued_subjects
        end
      end

      describe "user has or workflow is finished" do
        let(:queue_owner) { nil }
        before(:each) do
          subject_queue
        end

        shared_examples "creates for the logged out user" do
          it 'should create for logged out user' do
            expect(SubjectQueue).to receive(:create_for_user).with(workflow, nil, set_id: nil)
            #non-logged in queue won't exist
            expect { subject.queued_subjects }.to raise_error(Subjects::Selector::MissingSubjectQueue)
          end
        end

        context "when the workflow is finished" do
          before(:each) do
            allow_any_instance_of(Workflow).to receive(:finished?).and_return(true)
          end

          context "when the logged_out queue doesn't exist" do
            let(:queue_owner) { user.user }

            it_behaves_like "creates for the logged out user"
          end
        end

        context "when the user has finished the workflow" do
          before(:each) do
            allow_any_instance_of(User).to receive(:has_finished?).and_return(true)
          end

          context "when the logged_out queue doesn't exist" do
            let(:queue_owner) { user.user }

            it_behaves_like "creates for the logged out user"
          end
        end
      end
    end
  end

  describe '#selected_subjects' do
    it 'should not return retired subjects' do
      sms = smses[0]
      swc = create(:subject_workflow_count, subject: sms.subject, retired_at: Time.zone.now)
      result = subject.selected_subjects(subject_queue).map do |subj|
        subj.set_member_subjects.first.id
      end.sort

      expect(result).to eq(subject_queue.set_member_subject_ids[1..-1].sort)
    end
  end
end
