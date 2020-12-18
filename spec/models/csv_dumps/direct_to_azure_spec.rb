# frozen_string_literal: true

require 'spec_helper'

describe CsvDumps::DirectToAzure, :focus do
  let(:direct_to_azure) { described_class.new("full") }
  let(:adapter) { direct_to_azure.storage_adapter('azure') }
  let(:file_name) { 'full_email_list' }
  let(:azure_path) { "email_exports/#{file_name}.csv" }
  let(:put_opts) do
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"#{file_name}.csv\""
    }
  end
  let(:file_path) { '/tmp/foobar' }

  let(:opts) do
    {
      azure_storage_account: 'zooniverse-exports',
      azure_storage_access_key: 'fake-key',
      azure_storage_container_public: nil,
      azure_storage_container_private: 'private'
    }
  end
  let(:test_adapter) { MediaStorage::TestAdapter.new(opts) }

  it 'uses the azure adapter by default' do
    allow(MediaStorage).to receive(:load_adapter)
    described_class.new('full').storage_adapter
    expect(MediaStorage).to have_received(:load_adapter).with('azure', opts)
  end

  context 'with the test adapter' do
    before do
      allow(MediaStorage).to receive(:load_adapter).with(:azure, opts).and_return(test_adapter)
    end

    it 'wires up the correct storage adapter with custom storage opts' do
      adapter
      expect(MediaStorage).to have_received(:load_adapter).with('test', opts)
    end

    describe 'uploading using put_file' do
      it 'uses the storage adapter to construct the put_file path' do
        allow(adapter).to receive(:stored_path).and_call_original
        direct_to_azure.put_file(file_path)
        expect(adapter).to have_received(:stored_path).with('text/csv', 'email_exports')
      end

      it 'uploads the file to the the correct s3 bucket location' do
        allow(adapter).to receive(:put_file)
        direct_to_azure.put_file(file_path)
        expect(adapter).to have_received(:put_file).with(azure_path, file_path, put_opts)
      end
    end

    describe 'container public check' do
      it "should raise an error if the target container is public" do
        allow(adapter).to receive(:safe_for_private_upload?).and_return(false)
        expect{
          direct_to_azure.put_file(file_path)
        }.to raise_error(CsvDumps::DirectToAzure::NonPrivateContainer, 'the destination container is public')
      end

      it "should not raise when the container is private" do
        expect{ direct_to_azure.put_file(file_path) }.not_to raise_error
      end
    end
  end
end
