require 'spec_helper'

RSpec.describe SubjectSelector do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:user) { ApiUser.new(create(:user)) }
  let(:smses) { create_list(:set_member_subject, 10).reverse }

  let(:subject_queue) do
    create(:subject_queue,
           workflow: workflow,
           user: nil,
           subject_set: nil,
           set_member_subjects: smses)
  end

  subject { described_class.new(user, workflow, {}, Subject.all)}

  describe "#queued_subjects" do

    it 'should return url_format: :get in the context object' do
      subject_queue
      _, ctx = subject.queued_subjects
      expect(ctx).to include(url_format: :get)
    end

    it "should respect the order of subjects in the queue" do
      subject_queue
      subjects, _ = subject.queued_subjects
      expected_order = smses.map(&:subject_id)
      expect(subjects.pluck(:id)).to eq(expected_order)
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
          expect{subject.queued_subjects}.to raise_error(SubjectSelector::MissingSubjectSet,
            "no subject set is associated with this workflow")
        end
      end
    end

    context "when the params page size is set as a string" do
      let(:size) { 2 }
      subject do
        described_class.new(user, workflow, {page_size: "#{size}"}, Subject.all)
      end

      it 'should return the page_size number of subjects' do
        subject_queue
        subjects, _ = subject.queued_subjects
        expect(subjects.length).to eq(size)
      end
    end

    context "queue is empty" do
      let(:subject_queue) do
        create(:subject_queue,
               workflow: workflow,
               user: user.user,
               subject_set: nil,
               set_member_subjects: [])
      end
      let!(:subjects) { create_list(:set_member_subject, 10, subject_set: workflow.subject_sets.first) }

      it 'should return 5 subjects' do
        subject_queue
        subjects, _ = subject.queued_subjects
        expect(subjects.length).to eq(5)
      end

      context "when the database selection returns an empty set" do

        it 'should raise the an error when ordering by an empty set' do
          allow_any_instance_of(PostgresqlSelection).to receive(:select).and_return([])
          subject_queue
          message = "No data available for selection"
          expect { subject.queued_subjects }.to raise_error(SubjectSelector::EmptyDatabaseSelect, message)
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

        it 'should call dequeue_subject for the user' do
          expect(DequeueSubjectQueueWorker).to receive(:perform_async)
            .with(workflow.id, array_including(sms_ids), nil, nil)
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
            expect { subject.queued_subjects }.to raise_error(SubjectSelector::MissingSubjectQueue)
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
end
