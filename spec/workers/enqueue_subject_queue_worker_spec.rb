require "spec_helper"

RSpec.describe EnqueueSubjectQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }

  describe "#perform" do

    before(:each) do
      available_smss = (1..100).to_a
      allow_any_instance_of(Subjects::PostgresqlSelection).to receive(:select).and_return(available_smss)
    end

    context "with no user or set" do
      it 'should create a subject queue with the default number of items' do
        subject.perform(workflow.id)
        queue = SubjectQueue.find_by(workflow: workflow)
        expect(queue.set_member_subject_ids.length).to eq(100)
      end
    end

    context "when a workflow id string is passed in" do
      it "should not raise an error" do
        expect{subject.perform(workflow.id.to_s)}.to_not raise_error
      end
    end

    context "when the workflow does not exist" do
      it 'should not raise an error' do
        expect do
          subject.perform(-1)
        end.to_not raise_error
      end
    end

    context "when the strategy param is not set" do
      it "should fall back to postgresql strategy" do
        expect_any_instance_of(Subjects::PostgresqlSelection).to receive(:select)
        subject.perform(workflow.id)
      end
    end

    context "with a user" do

      it 'should create a subject queue for the user' do
        subject.perform(workflow.id, user.id)
        queue = SubjectQueue.by_user_workflow(user, workflow).first
        expect(queue.set_member_subject_ids.length).to eq(100)
      end
    end

    context "with user and a subject set" do

      it 'should create a per user subject set queue' do
        subject.perform(workflow.id, user.id, subject_set.id)
        queue = SubjectQueue.by_set(subject_set.id).by_user_workflow(user, workflow).first
        expect(queue.set_member_subject_ids.length).to eq(100)
      end
    end

    context "when selecting via cellect selection strategy" do
      it 'should attempt to queue the selected set' do
        allow_any_instance_of(Subjects::CellectClient).to receive(:get_subjects).and_return([1])
        expect(SubjectQueue).to receive(:enqueue)
        subject.perform(workflow.id)
      end

      context "when the cellect client can't reach a server" do

        it "should fall back to postgres strategy" do
          allow(Subjects::CellectClient).to receive(:get_subjects)
            .and_raise(Subjects::CellectClient::ConnectionError)
          expect_any_instance_of(Subjects::PostgresqlSelection).to receive(:select)
          subject.perform(workflow.id, nil, nil, nil, :cellect)
        end
      end
    end

    context "when subjects are selected" do
      before do
        allow_any_instance_of(Subjects::PostgresqlSelection).to receive(:select).and_return(result_ids)
      end

      context "when there are selected subjects to queue" do
        let(:result_ids) { [1] }

        it 'should attempt to queue the selected set' do
          expect(SubjectQueue).to receive(:enqueue)
          subject.perform(workflow.id)
        end
      end

      context "when there are no selected subjects to queue" do
        let(:result_ids) { [] }

        it 'should not attempt to queue an empty set' do
          expect(SubjectQueue).to_not receive(:enqueue)
          subject.perform(workflow.id)
        end
      end
    end
  end
end
