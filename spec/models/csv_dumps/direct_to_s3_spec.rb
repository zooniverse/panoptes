require 'spec_helper'

describe CsvDumps::DirectToS3 do
  let(:direct_to_s3) { described_class.new("full") }
  let(:adapter) { direct_to_s3.send(:storage_adapter) }
  let(:s3_file_name) { "full_email_list" }
  let(:s3_path) { "email_exports/#{s3_file_name}.tar.gz" }
  let(:s3_opts) do
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"#{s3_file_name}.csv\""
    }
  end
  let(:file_path) { "/tmp/foobar" }

  describe "uses custom storage adapter" do
    it "should receive custom storage opts" do
      opts = {
        bucket: 'zooniverse-exports',
        prefix: "#{Rails.env}/"
      }
      expect(MediaStorage)
        .to receive(:load_adapter)
        .with("test", opts)
        .and_call_original
      direct_to_s3.put_file(file_path)
    end

    it "should upload the file to the a known bucket location" do
      expect(adapter)
        .to receive(:stored_path)
        .with("application/x-gzip", "email_exports")
        .and_call_original
      expect(adapter)
        .to receive(:put_file)
        .with(s3_path, file_path, s3_opts)
      direct_to_s3.put_file(file_path)
    end
  end

  describe "bucket encryption" do
    it "should raise an error if it's not encrypted" do
      adapter = direct_to_s3.storage_adapter
      allow(adapter).to receive(:encrypted_bucket?).and_return(false)
      expect{
        direct_to_s3.put_file(file_path)
      }.to raise_error(CsvDumps::DirectToS3::UnencryptedBucket, "the destination bucket is not encrypted")
    end

    it "should not raise when the bucket is encrypted" do
      expect{ direct_to_s3.put_file(file_path) }.not_to raise_error
    end
  end
end
