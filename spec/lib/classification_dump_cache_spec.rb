require 'spec_helper'

describe ClassificationDumpCache do
  describe '#workflow_at_version' do
    let(:workflow_version_1_1) { build(:workflow_version, major_number: 1, minor_number: 1) }
    let(:workflow_version_1_2) { build(:workflow_version, major_number: 1, minor_number: 2) }
    let(:workflow_version_2_2) { build(:workflow_version, major_number: 2, minor_number: 2) }
    let(:workflow_version_3_3) { build(:workflow_version, major_number: 3, minor_number: 3) }
    let(:workflow_version_6_6) { build(:workflow_version, major_number: 6, minor_number: 6) }

    let(:workflow) do
      create :workflow,
        major_version: 3,
        minor_version: 3,
        workflow_versions: [
          workflow_version_1_2,
          workflow_version_2_2,
          workflow_version_3_3,
          workflow_version_6_6
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
      expect(cache.workflow_at_version(workflow, 7, 7)).to eq(workflow_version_6_6)
    end

    it 'returns the workflow itself if the requested version is the latest, but no WorkflowVersion record exists' do
      workflow.workflow_versions.delete_all
      cache = described_class.new
      workflow_at_version = cache.workflow_at_version(workflow, 4, 4)
      expect(workflow_at_version).to be_instance_of(WorkflowVersion)
      expect(workflow_at_version.major_number).to eq(4)
      expect(workflow_at_version.minor_number).to eq(4)
    end
  end
end
