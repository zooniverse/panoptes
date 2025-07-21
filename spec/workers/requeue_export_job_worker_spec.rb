require 'spec_helper'
require 'sidekiq-status'
require 'sidekiq/api'

RSpec.describe RequeueExportJobWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:export_type) { described_class::EXPORT_MEDIA_TYPES.first }
  let(:metadata) { {} }
  let(:media) { create(:medium, type: export_type, metadata: metadata, content_type: 'text/csv') }

  let(:retry_set) { instance_double(Sidekiq::RetrySet) }
  let(:dead_set)  { instance_double(Sidekiq::DeadSet) }

  before do
    allow(Sidekiq::Queue).to receive(:all).and_return([])
    allow(Sidekiq::RetrySet).to receive(:new).and_return(retry_set)
    allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_set)

    allow(dead_set).to receive(:find_job).and_return(nil)
  end

  describe '#perform' do
    context 'when no export media exists' do
      it 'logs and returns nil' do
        allow(Medium).to receive(:where).and_return(Medium.none)
        expect(worker.perform).to be_nil
      end
    end

    context 'with uncompleted export media' do
      before do
        create_list(:medium, 2, type: export_type, metadata: { 'state' => 'creating' }, content_type: 'text/csv')
      end

      it 'calls process_media_status for each record' do
        expect(worker).to receive(:process_media_status).twice
        worker.perform
      end
    end
  end

  describe '#process_media_status' do
    subject { worker.send(:process_media_status, media) }

    context 'when metadata has no job_id' do
      let(:metadata) { { 'state' => 'creating' } }

      it 'marks media as failed' do
        subject
        expect(media.reload.metadata['state']).to eq(RequeueExportJobWorker::STATE_FAILED)
      end
    end

    context 'when Sidekiq status is :complete' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid123' } }

      before do
        allow(Sidekiq::Status).to receive(:status).with('jid123').and_return(:complete)
      end

      it 'marks media as completed' do
        subject
        expect(media.reload.metadata['state']).to eq(RequeueExportJobWorker::STATE_COMPLETED)
      end
    end

    context 'when job failed and requeue succeeds' do
      let(:metadata) { { 'state' => 'failed', 'job_id' => 'jid456' } }
      let(:retry_job) { double('job', requeue: true) }

      before do
        allow(Sidekiq::Status).to receive(:status).with('jid456').and_return(:failed)
        allow(retry_set).to receive(:find_job).with('jid456').and_return(retry_job)
      end

      it 'marks media as requeued' do
        subject
        expect(media.reload.metadata['state']).to eq(RequeueExportJobWorker::STATE_REQUEUED)
      end
    end

    context 'when job failed and requeue fails' do
      let(:metadata) { { 'state' => 'failed', 'job_id' => 'jid789' } }

      before do
        allow(Sidekiq::Status).to receive(:status).with('jid789').and_return(:failed)
        allow(retry_set).to receive(:find_job).with('jid789').and_return(nil)
        allow(dead_set).to receive(:find_job).with('jid789').and_return(nil)
      end

      it 'marks media as failed and clears job_id' do
        subject
        reloaded = media.reload.metadata
        expect(reloaded['state']).to eq(RequeueExportJobWorker::STATE_FAILED)
        expect(reloaded['job_id']).to be_nil
      end
    end

    context 'when job is still active' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid101' } }

      before do
        allow(Sidekiq::Status).to receive(:status).with('jid101').and_return(:working)
      end

      it 'does not change state' do
        subject
        expect(media.reload.metadata['state']).to eq('creating')
      end
    end

    context 'when status is nil and job found via RetrySet' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid202' } }
      let(:retry_job) { double('job', requeue: true) }

      before do
        allow(Sidekiq::Status).to receive(:status).with('jid202').and_return(nil)
        allow(retry_set).to receive(:find_job).with('jid202').and_return(retry_job)
      end

      it 'requeues and leaves state unchanged' do
        subject
        expect(media.reload.metadata['state']).to eq('creating')
      end
    end

    context 'when status is nil and job not found in any set' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid303' } }

      before do
        allow(Sidekiq::Status).to receive(:status).with('jid303').and_return(nil)
        allow(retry_set).to receive(:find_job).with('jid303').and_return(nil)
        allow(dead_set).to receive(:find_job).with('jid303').and_return(nil)
      end

      it 'marks media as completed' do
        subject
        expect(media.reload.metadata['state']).to eq(RequeueExportJobWorker::STATE_COMPLETED)
      end
    end
  end
end
