require 'spec_helper'

describe Workflows::RetireSubjects do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:workflow) { create :workflow }

  let(:subject_set) { create(:subject_set, project: workflow.project, workflows: [workflow]) }
  let(:subject_set_id) { subject_set.id }
  let(:subject1) { create(:subject, subject_sets: [subject_set]) }
  let(:subject2) { create(:subject, subject_sets: [subject_set]) }

  let(:operation) { described_class.with(api_user: api_user) }

  it 'sets a valid retirement reason' do
    operation.run! workflow: workflow, subject_id: subject1.id, retirement_reason: "nothing_here"
    expect(SubjectWorkflowStatus.by_subject_workflow(subject1.id, workflow.id).retirement_reason)
      .to match("nothing_here")
  end

  it 'is invalid with an invalid retirement reason' do
    result = operation.run workflow: workflow, subject_id: subject1.id, retirement_reason: "nope"
    expect(result).not_to be_valid
  end

  it 'is valid with a missing parameter' do
    result = operation.run workflow: workflow, subject_id: subject1.id
    expect(result).to be_valid
  end

  context 'with a single subject_id' do
    it 'retires the subject' do
      operation.run! workflow: workflow, subject_id: subject1.id
      expect(subject1.retired_for_workflow?(workflow)).to be_truthy
    end

    it 'queues a workflow retired counter' do
      expect(WorkflowRetiredCountWorker).to receive(:perform_async).with(workflow.id)
      operation.run! workflow: workflow, subject_id: subject1.id
    end

    it 'queues a cellect retirement if the workflow uses cellect' do
      allow(Panoptes).to receive(:use_cellect?).and_return(true)
      expect(RetireCellectWorker).to receive(:perform_async).with(subject1.id, workflow.id)
      operation.run! workflow: workflow, subject_id: subject1.id
    end
  end

  context 'with a list of subject_ids' do
    it 'retires the subject' do
      operation.run! workflow: workflow, subject_ids: [subject1.id, subject2.id]
      expect(subject1.retired_for_workflow?(workflow)).to be_truthy
      expect(subject2.retired_for_workflow?(workflow)).to be_truthy
    end

    it 'does not queue workers if something went wrong' do
      allow(Panoptes).to receive(:use_cellect?).and_return(true)
      allow(workflow).to receive(:retire_subject).with(subject1.id, nil).and_return(true)
      allow(workflow).to receive(:retire_subject).with(subject2.id, nil) { raise "some error" }
      expect(WorkflowRetiredCountWorker).to receive(:perform_async).with(workflow.id).never
      expect(RetireCellectWorker).to receive(:perform_async).with(subject1.id, workflow.id).never
      expect do
        operation.run! workflow: workflow, subject_ids: [subject1.id, subject2.id]
      end.to raise_error(RuntimeError, 'some error')
    end
  end
end
