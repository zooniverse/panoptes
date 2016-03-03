require 'spec_helper'

describe Workflows::RetireSubjects do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:workflow) { create :workflow }

  let(:subject_set) { create(:subject_set, project: workflow.project, workflows: [workflow]) }
  let(:subject_set_id) { subject_set.id }
  let(:subject1) { create(:subject, subject_sets: [subject_set]) }
  let(:subject2) { create(:subject, subject_sets: [subject_set]) }

  let(:operation) { described_class.with(api_user: api_user) }

  context 'with a single subject_id' do
    it 'retires the subject' do
      operation.run! workflow: workflow, subject_id: subject1.id
      expect(subject1.retired_for_workflow?(workflow)).to be_truthy
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

    it 'queues a cellect retirement if the workflow uses cellect' do
      allow(Panoptes).to receive(:use_cellect?).and_return(true)
      expect(RetireCellectWorker).to receive(:perform_async).with(subject1.id, workflow.id)
      expect(RetireCellectWorker).to receive(:perform_async).with(subject2.id, workflow.id)
      operation.run! workflow: workflow, subject_ids: [subject1.id, subject2.id]
    end

    it 'does not queue workers if something went wrong' do
      allow(Panoptes).to receive(:use_cellect?).and_return(true)
      allow(workflow).to receive(:retire_subject).with(subject1.id).and_return(true)
      allow(workflow).to receive(:retire_subject).with(subject2.id) { raise ActiveRecord::Rollback, "some error" }
      expect(RetireCellectWorker).to receive(:perform_async).with(subject1.id, workflow.id).never
      operation.run! workflow: workflow, subject_ids: [subject1.id, subject2.id]
    end
  end
end
