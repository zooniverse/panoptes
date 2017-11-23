require 'spec_helper'

describe CsvDumps::DirectToS3 do
  let(:direct_to_s3) { described_class.new("full") }
  let(:adapter) { direct_to_s3.send(:storage_adapter) }

  let(:s3_path) { "email_exports/full_email_list.tar.gz" }
  let(:s3_opts) do
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"full_email_list.csv\"",
      signature_version: :v4
    }
  end
  let(:file_path) { "/tmp/foobar" }

  it "should use a custom storage adapter" do
    opts = {
      bucket: 'zooniverse-exports',
      prefix: "emails/#{Rails.env}/"
    }
    expect(MediaStorage)
      .to receive(:load_adapter)
      .with("test", opts)
      .and_call_original
    direct_to_s3.put_file(file_path)
  end

  it "push the file to s3 the correct bucket location via a custom storage adapter" do
    expect(adapter)
      .to receive(:stored_path)
      .with("application/x-gzip", "email_exports")
      .and_call_original
    expect(adapter)
      .to receive(:put_file)
      .with(s3_path, file_path, s3_opts)
    direct_to_s3.put_file(file_path)
  end

  describe "bucket encryption", :focus do
    # resp = client.get_bucket_encryption({bucket: "BucketName"})

    it "should raise an error if it's not encrypted" do
      expect{
        direct_to_s3.put_file(file_path)
      }.to raise_error(UnencryptedBucket, "the destination bucket is not encrypted")
    end

    it "should not raise when the bucket is encrypted" do
      expect{ direct_to_s3.put_file(file_path) }.not_to raise_error
    end
  end
end
