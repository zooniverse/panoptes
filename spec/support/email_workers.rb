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
    worker.perform(export_params)
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

  it "push the file to s3 at the correct bucket location" do
    adapter = MediaStorage.adapter
    expect(MediaStorage).to receive(:stored_path)
      .with("application/x-gzip", "email_exports")
      .and_call_original
    expect(adapter)
      .to receive(:put_file)
      .with(s3_path, an_instance_of(String), s3_opts)
    expect(worker).to receive(:write_to_s3).and_call_original
  end

  it "should clean up the csv and compressed files after sending to s3" do
    expect(worker).to receive(:remove_tempfile).twice
  end
end
