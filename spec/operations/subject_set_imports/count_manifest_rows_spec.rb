# frozen_string_literal: true

require 'spec_helper'

describe SubjectSetImports::CountManifestRows do
  let(:source_url) { 'https://example.org/file.csv' }
  let(:user) { build_stubbed(:user) }
  let(:api_user) { ApiUser.new(user) }
  let(:data_row_count) { 2 }
  let(:operation_params) { { source_url: source_url } }
  let(:operation) { described_class.with(api_user: api_user) }

  before do
    allow(UrlDownloader).to receive(:stream).and_yield(true)
    csv_import_double = instance_double(SubjectSetImport::CsvImport, count: data_row_count)
    allow(SubjectSetImport::CsvImport).to receive(:new).and_return(csv_import_double)
  end

  it 'is invalid without the source_url param' do
    expect {
      operation.run!(operation_params.except(:source_url))
    }.to raise_error(ActiveInteraction::InvalidInteractionError, 'Source url is required')
  end

  it 'is invalid with a non url format source_url param' do
    expect {
      operation.run!({ source_url: 'just a string'} )
    }.to raise_error(SubjectSetImports::CountManifestRows::InvalidUrl, 'Source url is malformed')
  end

  it 'returns the data row count of the manifest' do
    outcome = operation.run!(operation_params)
    expect(outcome).to eq(data_row_count)
  end

  context 'when the manifest is over the limit' do
    before do
      allow(ENV).to receive(:fetch).with('SUBJECT_SET_IMPORT_MANIFEST_ROW_LIMIT', 10000).and_return('1')
    end

    it 'raises an error code when the manifest is over the limit' do
      expect {
        operation.run!(operation_params)
      }.to raise_error(SubjectSetImports::CountManifestRows::LimitExceeded, 'Manifest row count (2) exceeds the limit (1) and can not be imported')
    end

    it 'skips validation for admin uploads' do
      allow(api_user).to receive(:is_admin?).and_return(true)
      expect {
        operation.run!(operation_params)
      }.not_to raise_error
    end
  end

  context 'when the manifest is not publically available' do
    let(:error_message) { '404 - Failed to download URL: $URL' }
    let(:operation_error_message) { "Failed to download manifest: #{source_url}" }

    before do
      allow(UrlDownloader).to receive(:stream).and_raise(UrlDownloader::Failed, error_message)
    end

    it 'raises a relevant error' do
      expect {
        operation.run!(operation_params)
      }.to raise_error(SubjectSetImports::CountManifestRows::ManifestError, operation_error_message)
    end

    it 'raises an error on admin uploads' do
      allow(api_user).to receive(:is_admin?).and_return(true)
      expect {
        operation.run!(operation_params)
      }.to raise_error(SubjectSetImports::CountManifestRows::ManifestError, operation_error_message)
    end
  end
end
