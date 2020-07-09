require 'spec_helper'

RSpec.describe MediaStorage::AzureAdapter do
  let(:storage_account_name) { 'tiny-watermelons' }
  let(:container) { 'test' }
  let(:opts) do
    {
      azure_storage_account: storage_account_name,
      azure_storage_access_key: 'fake',
      azure_storage_container: container,
      stub_responses: true
    }
  end
  let(:adapter) { described_class.new(opts) }
  let(:uri_regex) { /\A#{URI::DEFAULT_PARSER.make_regexp}\z/ }
  let(:uuid_v4_regex) { /[a-f0-9]{8}\-[a-f0-9]{4}\-4[a-f0-9]{3}\-(8|9|a|b)[a-f0-9]{3}\-[a-f0-9]{12}/ }

  context 'when opts are passed to the initializer' do
    it 'uses default expiration values when no expiration values are passed' do
      default = MediaStorage::AzureAdapter::DEFAULT_EXPIRES_IN
      expect(adapter.instance_variable_get(:@get_expiration)).to eq(default)
      expect(adapter.instance_variable_get(:@put_expiration)).to eq(default)
    end

    it 'defaults to current rails environment for the container name when no container is given' do
      adapter = described_class.new(opts.except(:azure_storage_container))
      expect(adapter.instance_variable_get(:@container)).to eq('test')
    end

    it 'creates the blob storage client using passed in options' do
      allow(Azure::Storage::Blob::BlobService).to receive(:create)

      adapter
      expect(Azure::Storage::Blob::BlobService)
        .to have_received(:create)
        .with(
                storage_account_name: opts[:azure_storage_account],
                storage_access_key: opts[:azure_storage_access_key]
             )
    end

    it 'initializes the signer using passed in options' do
      allow(Azure::Storage::Common::Core::Auth::SharedAccessSignature).to receive(:new)

      adapter
      expect(Azure::Storage::Common::Core::Auth::SharedAccessSignature)
        .to have_received(:new)
        .with(opts[:azure_storage_account], opts[:azure_storage_access_key])
    end
  end

  describe '#stored_path' do
    subject { adapter.stored_path('image/jpeg', 'subject_location') }

    it { is_expected.to be_a(String) }
    it { is_expected.to match(/subject_location/) }
    it { is_expected.to match(/\.jpeg/) }
    it { is_expected.to match(uuid_v4_regex) }

    context 'with additional path prefixes' do
      subject { adapter.stored_path('image/jpeg', 'subject_location', 'extra', 'prefixes') }

      it { is_expected.to match(%r{extra\/prefixes}) }
    end

    context 'with an application/x-gzip content-type' do
      subject { adapter.stored_path('application/x-gzip', 'subject_location') }

      it { is_expected.to match(/\.tar\.gz\z/) }
    end
  end

  shared_examples 'presigned url' do
    it { is_expected.to match(uri_regex) }
    it { is_expected.to match(/\Ahttps:\/\/#{storage_account_name}.blob.core.windows.net\/#{container}\//) }
    it 'sets expiry time in the url' do
      allow(adapter).to receive(:get_expiry_time).and_return('2020-07-06T18:05:29Z')

      it { is expected.to match(/se=2020-07-06T18:05:29Z}/) }
    end
  end

  describe '#get_path' do
    subject { adapter.get_path('subject_locations/name.jpg') }

    it_behaves_like 'presigned url'
    it { is_expected.to match(/sp=r&sv=\d{4}-\d{2}-\d{2}&se=\d{4}-\d{2}-\d{2}T[%A0-9]+Z&sr=b&sig=[%A-z0-9]+\z/) }
    it { is_expected.to match(/subject_locations\/name.jpg/) }

    context 'when get_expires option is set' do
      let(:upload_options) { { get_expires: 10 } }

      it 'uses passed in option for generating expiry time' do
        allow(adapter).to receive(:get_expiry_time)

        adapter.get_path('subject_locations/name.jpg', upload_options)
        expect(adapter).to have_received(:get_expiry_time).with(10)
      end
    end
  end

  describe '#put_path' do
    subject { adapter.put_path('subject_locations/name.jpg') }
    let(:upload_options) { { content_type: 'image/jpeg' } }

    it_behaves_like 'presigned url'
    it { is_expected.to match(/sp=rcw&sv=\d{4}-\d{2}-\d{2}&se=\d{4}-\d{2}-\d{2}T[%A0-9]+Z&sr=b&sig=[%A-z0-9]+\z/) }
    it { is_expected.to match(/subject_locations\/name.jpg/) }

    context 'when put_expires option is set' do
      it 'uses passed in option for generating expiry time' do
        allow(adapter).to receive(:get_expiry_time)
        upload_options[:put_expires] = 10

        adapter.put_path('subject_locations/name.jpg', upload_options)
        expect(adapter).to have_received(:get_expiry_time).with(10)
      end
    end
  end

  describe '#put_file' do
    let(:file) { instance_double('File') }
    let(:blob_client) { instance_double('Azure::Storage::Blob::BlobService') }
    let(:method_call_options) { { content_type: 'text/plain' } }

    before do
      allow(file).to receive(:close)
      allow(File).to receive(:open) { file }

      allow(Azure::Storage::Blob::BlobService).to receive(:create) { blob_client }
      allow(blob_client).to receive(:create_block_blob)
    end

    it 'calls the create_block_blob method with correct arguments' do
      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client).to have_received(:create_block_blob).with(container, 'storage_path.txt', file, method_call_options)
    end

    it 'sets content encoding to gzip if compressed option is set' do
      method_call_options[:compressed] = true
      expected_blob_client_options = { content_type: 'text/plain', content_encoding: 'gzip' }

      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client).to have_received(:create_block_blob).with(container, 'storage_path.txt', file, expected_blob_client_options)
    end

    it 'passes content disposition to the blob client when option is set' do
      method_call_options[:content_disposition] = 'attachment'

      adapter.put_file('storage_path.txt', 'path_to_file.txt', method_call_options)
      expect(blob_client).to have_received(:create_block_blob).with(container, 'storage_path.txt', file, method_call_options)
    end
  end

  describe '#delete_file' do
    let(:blob_client) { instance_double('Azure::Storage::Blob::BlobService') }

    it 'calls the delete_blob method with correct arguments' do
      allow(Azure::Storage::Blob::BlobService).to receive(:create) { blob_client }
      allow(blob_client).to receive(:delete_blob)

      adapter.delete_file('path_to_file.txt')
      expect(blob_client).to have_received(:delete_blob).with(container, 'path_to_file.txt')
    end
  end

  describe '#encrypted_bucket?' do
    it 'returns true' do
      expect(adapter.encrypted_bucket?).to eq(true)
    end
  end
end
