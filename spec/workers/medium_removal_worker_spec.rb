# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MediumRemovalWorker do
  subject(:worker) { described_class.new }

  let(:medium_src) { 'test/path.txt' }

  it 'deletes the given src path' do
    allow(MediaStorage).to receive(:delete_file)
    worker.perform(medium_src)
    expect(MediaStorage).to have_received(:delete_file).with(medium_src, {})
  end

  it 'ignores any missing s3 (access denied) media paths' do
    allow(MediaStorage)
      .to receive(:delete_file)
      .and_raise(Aws::S3::Errors::AccessDenied.new(:s3, 'fake denied'))
    expect { worker.perform(medium_src) }.not_to raise_error
  end

  it 'ignores any missing azure (BlobNotFound (404)) media paths' do
    require 'azure/core/http/http_error'
    response = instance_double('Azure::Core::Http::HTTPResponse', uri: 'fake-uri', status_code: 404, body: '', reason_phrase: '')
    allow(MediaStorage).to receive(:delete_file).and_raise(Azure::Core::Http::HTTPError, response)
    expect { worker.perform(medium_src) }.not_to raise_error(Azure::Core::Http::HTTPError)
  end

  it 'raises any unknown azure responses' do
    require 'azure/core/http/http_error'
    response = instance_double('Azure::Core::Http::HTTPResponse', uri: 'fake-uri', status_code: 500, body: '', reason_phrase: '')
    allow(MediaStorage).to receive(:delete_file).and_raise(Azure::Core::Http::HTTPError, response)
    expect { worker.perform(medium_src) }.to raise_error(Azure::Core::Http::HTTPError)
  end

  it 'does not modify the storage path for the object store when not using azure adapter' do
    allow(MediaStorage).to receive(:delete_file)
    allow(MediaStorage::StoredPath).to receive(:media_path)
    worker.perform(medium_src)
    expect(MediaStorage::StoredPath).not_to have_received(:media_path)
  end

  context 'when using an azure storage adapter' do
    before do
      allow(MediaStorage).to receive(:delete_file)
      azure_adapter = instance_double('MediaStorage::AzureAdapter', is_a?: true)
      allow(MediaStorage).to receive(:get_adapter).and_return(azure_adapter)
    end

    it 'modifies the storage path for the azure blob object store' do
      allow(MediaStorage::StoredPath).to receive(:media_path)
      worker.perform(medium_src)
      expect(MediaStorage::StoredPath).to have_received(:media_path)
    end
  end
end
