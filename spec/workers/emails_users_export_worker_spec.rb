require 'spec_helper'

describe EmailsUsersExportWorker do
  let(:worker) { described_class.new }

  it { is_expected.to be_a Sidekiq::Worker }

  shared_examples "an email dump exporter" do

    RSpec::Matchers.define :a_formatted_user_email do |x|
      match do |csv_row|
        csv_row.is_a?(Array) &&
        csv_row.length == 1
        csv_row.first.match(/.+@.+/)
      end
    end

    let(:users) { create_list(:user, 2) }
    let(:inactive_user) { create(:user, activated_state: :inactive) }
    let(:invalid_email_user) { create(:user, valid_email: false) }

    before do
      users
      inactive_user
      invalid_email_user
    end

    after do
      worker.perform(export_type)
    end

    it "should create a csv file with the correct number of entries" do
      expect_any_instance_of(CSV)
        .to receive(:<<)
        .with(a_formatted_user_email)
        .exactly(users.length)
        .times
    end

    it "should compress the csv file" do
      expect(worker).to receive(:to_gzip).and_call_original
    end

    it "push the file to s3" do
      expect(MediaStorage)
        .to receive(:stored_path)
        .with("application/x-gzip", "email_exports")
      expect(MediaStorage)
        .to receive(:put_file)
        .with(an_instance_of(String), an_instance_of(String), s3_opts)
      expect(worker).to receive(:write_to_s3)
    end
    #
    # it "should clean up the file after sending to s3" do
    #   expect(worker).to receive(:remove_tempfile).once.and_call_original
    # end
  end

  it_behaves_like "an email dump exporter", :focus  do
    let!(:non_global_user) { create(:user, global_email_communication: false) }
    let(:s3_opts) do
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"global_email_list.csv\""
      }
    end
    let(:export_type) { :global }
  end

  it_behaves_like "an email dump exporter", :focus do
    let!(:non_beta_user) { create(:user, beta_email_communication: false) }
    let(:s3_opts) do
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"beta_email_list.csv\""
      }
    end
    let(:export_type) { :beta }
  end
end
