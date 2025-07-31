# spec/workers/requeue_export_job_worker_spec.rb

require 'spec_helper'
require 'sidekiq/api'

RSpec.describe RequeueExportJobWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:export_type) { described_class::EXPORT_MEDIA_TYPES.first }
  let(:metadata) { {} }
  let(:media) { create(:medium, type: export_type, metadata: metadata, content_type: 'text/csv') }
  let(:scheduled_set) { instance_double(Sidekiq::ScheduledSet) }
  let(:retry_set) { instance_double(Sidekiq::RetrySet) }
  let(:dead_set) { instance_double(Sidekiq::DeadSet) }

  before do
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_set)
    allow(Sidekiq::RetrySet).to receive(:new).and_return(retry_set)
    allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_set)

    allow(scheduled_set).to receive(:find_job).and_return(nil)
    allow(retry_set).to receive(:find_job).and_return(nil)
    allow(dead_set).to receive(:find_job).and_return(nil)

    allow(Sidekiq::Queue).to receive(:all).and_return([])
  end

  describe '#perform' do
    context 'when no export media exists' do
      it 'returns nil' do
        allow(Medium).to receive(:where).and_return(Medium.none)
        expect(worker.perform).to be_nil
      end
    end

    context 'with uncompleted export media' do
      before do
        create_list(
          :medium,
          2,
          type: export_type,
          metadata: { 'state' => 'creating' },
          content_type: 'text/csv',
          created_at: 2.days.ago
        )
        allow(worker).to receive(:process_media_status)
      end

      it 'calls process_media_status for each record' do
        worker.perform
        expect(worker).to have_received(:process_media_status).twice
      end
    end
  end

  describe '#process_media_status' do
    subject(:invoke_process_media_status) { worker.send(:process_media_status, media) }

    context 'when metadata has no job_id' do
      let(:metadata) { { 'state' => 'creating' } }

      it 'returns immediately and does not touch metadata' do
        expect { invoke_process_media_status }.not_to change { media.reload.metadata }
      end
    end

    context 'when job is in the scheduled set' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid_scheduled' } }

      before do
        allow(scheduled_set).to receive(:find_job).with('jid_scheduled').and_return(double)
        allow(worker).to receive(:requeue_from_media)
      end

      it 'does not requeue or change state' do
        invoke_process_media_status
        expect(worker).not_to have_received(:requeue_from_media)
        expect(media.reload.metadata['state']).to eq('creating')
      end
    end

    context 'when job is in the retry set' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid_retry' } }

      before do
        allow(retry_set).to receive(:find_job).with('jid_retry').and_return(double)
        allow(worker).to receive(:requeue_from_media)
      end

      it 'does not requeue or change state' do
        invoke_process_media_status
        expect(worker).not_to have_received(:requeue_from_media)
        expect(media.reload.metadata['state']).to eq('creating')
      end
    end

    context 'when job is in the dead set' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid_dead' } }

      before do
        allow(dead_set).to receive(:find_job).with('jid_dead').and_return(double)
        allow(worker).to receive(:update_media_metadata).and_call_original
      end

      it 'delegates to update_media_metadata with STATE_FAILED' do
        invoke_process_media_status
        expect(worker).to have_received(:update_media_metadata)
          .with(media, state: RequeueExportJobWorker::STATE_FAILED)
      end
    end

    context 'when the job is already in an active queue' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid_active' } }
      let(:fake_queue) { instance_double(Sidekiq::Queue, name: 'dumpworker', any?: true) }

      before do
        allow(Sidekiq::Queue).to receive(:all).and_return([fake_queue])
        allow(worker).to receive(:requeue_from_media)
      end

      it 'does not requeue or change state' do
        invoke_process_media_status
        expect(worker).not_to have_received(:requeue_from_media)
        expect(media.reload.metadata['state']).to eq('creating')
      end
    end

    context 'when metadata specifies recipients' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid_requeue', 'recipients' => [789] } }

      before do
        media.update!(type: 'project_subjects_export')
        allow(media).to receive(:path_opts).and_return([nil, 123])
        allow(SubjectsDumpWorker).to receive(:perform_async)
      end

      it 'uses the first recipient id instead of owner id' do
        invoke_process_media_status
        expect(SubjectsDumpWorker).to have_received(:perform_async)
          .with(123, media.linked_type.downcase, media.id, 789)
      end
    end

    context 'when nothing found (scheduled/retry/dead/queues) and a mapping exists' do
      let(:metadata) { { 'state' => 'creating', 'job_id' => 'jid_requeue' } }

      before do
        media.update!(type: 'project_subjects_export')
        allow(media).to receive(:path_opts).and_return([nil, 123])
        allow(worker).to receive(:get_media_owner).and_return(instance_double(User, id: 9))
        allow(SubjectsDumpWorker).to receive(:perform_async)
      end

      it 'calls perform_async on the mapped worker with correct args' do
        invoke_process_media_status
        expect(SubjectsDumpWorker).to have_received(:perform_async)
          .with(123, media.linked_type.downcase, media.id, 9)
      end

      it 'does not change state' do
        invoke_process_media_status
        expect(media.reload.metadata['state']).to eq('creating')
      end
    end
  end
end
