require 'spec_helper'

describe EmailsExportWorker do
  let(:worker) { described_class.new }
  it { is_expected.to be_a Sidekiq::Worker }

  it "should be scheduled to run daily at 3am" do
    expect(worker.class.schedule.to_s).to eq("Daily on the 3rd hour of the day")
  end

  it 'should not do any work if disabled' do
    expect(EmailsUsersExportWorker).not_to receive(:perform_async)
    expect(EmailsProjectsExportWorker).not_to receive(:perform_in)
    worker.perform
  end

  context "with the export email feature enabled" do
    before do
      Panoptes.flipper[:export_emails].enable
    end

    it 'enqueues an all users email export worker' do
      expect(EmailsUsersExportWorker).to receive(:perform_async).with(:global)
      worker.perform
    end

    it 'enqueues an beta users email export worker' do
      expect(EmailsUsersExportWorker)
        .to receive(:perform_in)
        .with(EmailsExportWorker::SPREAD, :beta)
      worker.perform
    end

    it 'enqueues a email export worker for each launch_approved project', :focus do
      projects = create_list(:project, 2)
      not_launched = create(:project, launch_approved: false)
      projects.each_with_index do |p, i|
        expect(EmailsProjectsExportWorker)
          .to receive(:perform_in)
          .with((EmailsExportWorker::SPREAD * 2 + 1), p.id)
      end
      worker.perform
    end
  end
end
