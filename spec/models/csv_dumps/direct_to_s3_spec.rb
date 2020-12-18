# frozen_string_literal: true

require 'spec_helper'

describe CsvDumps::DirectToS3 do
  let(:direct_to_s3) { described_class.new("full") }
  let(:adapter) { direct_to_s3.storage_adapter('test') }
  let(:s3_file_name) { "full_email_list" }
  let(:s3_path) { "email_exports/#{s3_file_name}.csv" }
  let(:s3_opts) do
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"#{s3_file_name}.csv\""
    }
  end
  let(:file_path) { "/tmp/foobar" }

  let(:opts) do
    {
      bucket: 'zooniverse-exports',
      prefix: "#{Rails.env}/"
    }
  end
  let(:test_adapter) { MediaStorage::TestAdapter.new(opts) }

  it 'uses the aws adapter by default' do
    allow(MediaStorage).to receive(:load_adapter)
    described_class.new('full').storage_adapter
    expect(MediaStorage).to have_received(:load_adapter).with('aws', opts)
  end

  context 'with the test adapter double' do
    before do
      allow(MediaStorage).to receive(:load_adapter).and_return(test_adapter)
    end

    it 'wires up the correct storage adapter with custom storage opts' do
      adapter
      expect(MediaStorage).to have_received(:load_adapter).with('test', opts)
    end

    describe 'uploading using put_file' do
      it 'correctly determines the s3 storage location path' do
        allow(adapter).to receive(:stored_path).and_call_original
        direct_to_s3.put_file(file_path)
        expect(adapter).to have_received(:stored_path).with('text/csv', 'email_exports')
      end

      it 'uploads the file to the the correct s3 bucket location' do
        allow(adapter).to receive(:put_file)
        direct_to_s3.put_file(file_path)
        expect(adapter).to have_received(:put_file).with(s3_path, file_path, s3_opts)
      end
    end

    describe 'bucket encryption' do
      it "raises an error if it's not encrypted" do
        allow(adapter).to receive(:encrypted_bucket?).and_return(false)
        expect {
          direct_to_s3.put_file(file_path)
        }.to raise_error(CsvDumps::DirectToS3::UnencryptedBucket, 'the destination bucket is not encrypted')
      end

      it 'does not raise when the bucket is encrypted' do
        expect { direct_to_s3.put_file(file_path) }.not_to raise_error
      end
    end
  end
end
