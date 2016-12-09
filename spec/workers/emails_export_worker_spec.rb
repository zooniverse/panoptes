require 'spec_helper'

describe EmailsExportWorker do
  let(:worker) { described_class.new }
  it { is_expected.to be_a Sidekiq::Worker }

  it "should be scheduled to run daily at 3am" do
    expect(worker.class.schedule.to_s).to eq("Daily on the 3rd hour of the day")
  end

  it 'should not do any work if disabled' do
    expect(UsersEmailExportWorker).not_to receive(:perform_async)
    expect(ProjectEmailExportWorker).not_to receive(:perform_in)
    worker.perform
  end

  context "with the export email feature enabled" do
    before do
      Panoptes.flipper[:export_emails].enable
    end

    it 'enqueues an all users email export worker' do
      expect(EmailsUsersExportWorker).to receive(:perform_async)
      worker.perform
    end

    it 'enqueues a email export worker for each launch_approved project' do
      projects = create_list(:project, 2)
      not_launched = create(:project, launch_approved: false)
      projects.each do |p|
        expect(ProjectEmailExportWorker)
          .to receive(:perform_in)
          .with(an_instance_of(Float), p.id)
      end
      worker.perform
    end
  end
end
