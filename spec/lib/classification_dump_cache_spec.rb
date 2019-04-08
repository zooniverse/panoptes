require 'spec_helper'

describe ClassificationDumpCache do
  describe '#workflow_at_version' do
    let(:workflow_version_1_1) { build(:workflow_version, major_number: 1, minor_number: 1) }
    let(:workflow_version_1_2) { build(:workflow_version, major_number: 1, minor_number: 2) }
    let(:workflow_version_2_2) { build(:workflow_version, major_number: 2, minor_number: 2) }
    let(:workflow_version_3_3) { build(:workflow_version, major_number: 3, minor_number: 3) }

    let(:workflow) do
      create :workflow, workflow_versions: [
        workflow_version_1_2,
        workflow_version_2_2,
        workflow_version_3_3
      ]
    end

    it 'finds the workflow at the specific version' do
      cache = described_class.new
      expect(cache.workflow_at_version(workflow, 1, 2)).to eq(workflow_version_1_2)
    end

    it 'finds a newer version if requested version does not exist' do
      cache = described_class.new
      expect(cache.workflow_at_version(workflow, 2, 3)).to eq(workflow_version_3_3)
    end

    it 'finds the latest version if requested version is newer than anything that exists' do
      cache = described_class.new
      expect(cache.workflow_at_version(workflow, 4, 5)).to eq(workflow_version_3_3)
    end
  end
end
