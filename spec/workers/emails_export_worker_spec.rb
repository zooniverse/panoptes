require 'spec_helper'
require 'sidekiq-cron'
require 'sidekiq'

describe EmailsExportWorker do
  let(:worker) { described_class.new }
  it { is_expected.to be_a Sidekiq::Worker }

  it 'should not do any work if disabled' do
    expect(EmailsUsersExportWorker).not_to receive(:perform_async)
    expect(EmailsProjectsExportWorker).not_to receive(:perform_in)
    worker.perform
  end

  context 'with sidekiq-cron scheduler' do
    let(:job) { Sidekiq::Cron::Job.new(name: 'emails_export_worker', cron: '0 3 * * *', class: described_class.name) }

    it 'gets queued daily at 3 am UTC' do
      now = Time.now.utc
      # sidekiq-cron has 10 second delay
      enqueued_time = Time.new(now.year, now.month, now.day, 3, 0, 0).utc + 10

      expect(job.should_enque?(enqueued_time)).to be true
    end

    it 'does not get enqueued if outside of 3 am UTC' do
      now = Time.now.utc
      outside_time = Time.new(now.year, now.month, now.day, 6, 0, 0).utc

      expect(job.should_enque?(outside_time)).to be false
    end
  end

  context "with the export email feature enabled" do
    before do
      Flipper.enable(:export_emails)
      allow(EmailsUsersExportWorker).to receive(:perform_in)
      allow(EmailsUsersExportWorker).to receive(:perform_async)
      allow(EmailsProjectsExportWorker).to receive(:perform_in)
    end

    it 'enqueues an all users email export worker' do
      worker.perform
      expect(EmailsUsersExportWorker).to have_received(:perform_async).with(:global)
    end

    it 'enqueues two email list export workers' do
      worker.perform
      expect(EmailsUsersExportWorker).to have_received(:perform_in).twice
    end

    it 'enqueues both beta and nasa email list export workers' do
      worker.perform
      expect(EmailsUsersExportWorker).to have_received(:perform_in).with(EmailsExportWorker::BETA_DELAY, :beta).ordered
      expect(EmailsUsersExportWorker).to have_received(:perform_in).with(EmailsExportWorker::NASA_DELAY, :nasa).ordered
    end

    it 'enqueues a email export worker for each launch_approved project' do
      projects = create_list(:project, 2)
      _not_launched = create(:project, launch_approved: false)
      worker.perform
      projects.each_with_index do |p, _i|
        expect(EmailsProjectsExportWorker).to have_received(:perform_in).with(an_instance_of(Float), p.id)
      end
    end
  end
end
