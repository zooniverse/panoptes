require 'spec_helper'

RSpec.describe MediaStorage::AzureAdapter do
  let(:storage_account_name) { "tiny-watermelons" }
  let(:container) { "test" }
  let(:opts) do
    {
      storage_account_name: storage_account_name,
      storage_access_key: 'fake',
      storage_container: container,
      stub_responses: true
    }
  end
  let(:adapter) { described_class.new(opts) }

  context 'when opts are passed to the initializer' do
    it 'should use default expiration values when no expiration values are passed' do
      default = MediaStorage::AzureAdapter::DEFAULT_EXPIRES_IN
      expect(adapter.instance_variable_get(:@get_expiration)).to eq(default)
      expect(adapter.instance_variable_get(:@put_expiration)).to eq(default)
    end

    it 'defaults to current rails environment for the container name when no container is given' do
      adapter = described_class.new(opts.except(:storage_container))
      expect(adapter.instance_variable_get(:@container)).to eq('test')
    end

    it 'should create the blob storage client using passed in options' do
      expect(Azure::Storage::Blob::BlobService)
        .to receive(:create)
        .with(opts.except(:storage_container, :stub_responses))
        .and_call_original
      adapter
    end

    it 'should initialize the signer using passed in options' do
      expect(Azure::Storage::Common::Core::Auth::SharedAccessSignature)
        .to receive(:new)
        .with(opts[:storage_account_name], opts[:storage_access_key])
        .and_call_original
      adapter
    end
  end
end