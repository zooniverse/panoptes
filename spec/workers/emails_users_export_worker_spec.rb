require 'spec_helper'

describe EmailsUsersExportWorker do
  let(:worker) { described_class.new }
  let(:users) { create_list(:user, 2) }

  it { is_expected.to be_a Sidekiq::Worker }

  it_behaves_like "an email dump exporter" do
    let!(:non_global_user) { create(:user, global_email_communication: false) }
    let(:scope_class) { CsvDumps::FullEmailList }
    let(:export_params) { :global }
  end

  it_behaves_like "an email dump exporter" do
    let!(:non_beta_user) { create(:user, beta_email_communication: false) }
    let(:scope_class) { CsvDumps::FullEmailList }
    let(:export_params) { :beta }
  end
end
