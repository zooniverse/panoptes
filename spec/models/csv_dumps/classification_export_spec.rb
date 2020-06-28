require 'spec_helper'

RSpec.describe ClassificationExport do
  let(:classification) { create(:classification) }
  let(:data) do
    {
      project_id: classification.project_id,
      workflow_id: classification.workflow_id,
      user_id: classification.user_id,
      user_name: 'DrFeelgoodz',
      workflow_name: 'AllZeTasks',
      workflow_version: classification.workflow_version,
      created_at: classification.created_at,
      gold_standard: classification.gold_standard,
      expert: classification.expert_classifier,
      metadata: classification.metadata,
      annotations: classification.annotations,
      subject_ids: '1,2'
    }
  end
  let(:formatter) do
    instance_double('Formatter::Csv::Classification', data)
  end

  describe '.format' do
    it 'returns the expected data' do
      expected_data = data.except(:created_at)
      expected_data[:classification_created_at] = classification.created_at
      expect(described_class.hash_format(formatter)).to include(expected_data)
    end
  end
end
