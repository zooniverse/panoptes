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

    describe '#put_file_with_retry' do
      it 'calls put_file with the src and other attributes' do
        allow(adapter).to receive(:put_file)
        direct_to_s3.put_file_with_retry(file_path)
        expect(adapter).to have_received(:put_file).with(s3_path, file_path, s3_opts)
      end

      it 'retries the correct number of times' do
        allow(adapter).to receive(:put_file).and_raise(Faraday::ConnectionFailed, 'some error in aws lib')
        direct_to_s3.put_file_with_retry(file_path)
      rescue Faraday::ConnectionFailed
        expect(adapter).to have_received(:put_file).with(s3_path, file_path, s3_opts).exactly(5).times
      end

      it 'allows the retry number to be modified at runtime' do
        allow(adapter).to receive(:put_file).and_raise(Faraday::ConnectionFailed, 'Connection reset by peer')
        direct_to_s3.put_file_with_retry(file_path, {}, 2)
      rescue Faraday::ConnectionFailed
        expect(adapter).to have_received(:put_file).with(s3_path, file_path, s3_opts).twice
      end

      it 'does not retry if put_file raises UnencryptedBucket' do
        allow(direct_to_s3).to receive(:put_file).and_raise(CsvDumps::DirectToS3::UnencryptedBucket)
        direct_to_s3.put_file_with_retry('')
      rescue CsvDumps::DirectToS3::UnencryptedBucket
        expect(direct_to_s3).to have_received(:put_file).once
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
