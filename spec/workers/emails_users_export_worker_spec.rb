require 'spec_helper'

describe EmailsUsersExportWorker do
  let(:worker) { described_class.new }

  it { is_expected.to be_a Sidekiq::Worker }

  it_behaves_like "an email dump exporter" do
    let!(:non_global_user) { create(:user, global_email_communication: false) }
    let(:s3_path) { "email_exports/global_email_list.tar.gz" }
    let(:s3_opts) do
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"global_email_list.csv\""
      }
    end
    let(:export_params) { :global }
  end

  it_behaves_like "an email dump exporter" do
    let!(:non_beta_user) { create(:user, beta_email_communication: false) }
    let(:s3_path) { "email_exports/beta_email_list.tar.gz" }
    let(:s3_opts) do
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"beta_email_list.csv\""
      }
    end
    let(:export_params) { :beta }
  end
end
