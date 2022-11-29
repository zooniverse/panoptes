# frozen_string_literal: true

require 'spec_helper'

describe SubjectSetImportSerializer do
  let(:subject_set_import) do
    create(:subject_set_import, source_url: 'https://example.com/manifest.csv', imported_count: 10, manifest_count: 20)
  end

  it_behaves_like 'a panoptes restpack serializer' do
    let(:resource) { subject_set_import }
    let(:includes) { [] }
    let(:preloads) { [] }
  end

  describe '#progress' do
    let(:resource_scope) { SubjectSetImport.where(id: subject_set_import.id) }
    let(:result) { described_class.single({}, resource_scope, {}) }

    it 'reports the correct progress' do
      expect(result[:progress]).to eq(0.5)
    end

    it 'handles 0 manifest count records correctly' do
      subject_set_import.update_column(:manifest_count, 0)
      expect(result[:progress]).to eq(0.0)
    end
  end
end
