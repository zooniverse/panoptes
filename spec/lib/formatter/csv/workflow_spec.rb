require "spec_helper"

RSpec.describe Formatter::Csv::Workflow, focus: true do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }

  let(:fields) do
    [  workflow.id,
       workflow.display_name,
       workflow.version_string,
       workflow.active,
       workflow.classifications_count,
       workflow.pairwise,
       workflow.grouped,
       workflow.prioritized,
       workflow.primary_language,
       workflow.first_task,
       workflow.tutorial_subject_id,
       workflow.retired_set_member_subjects_count,
       workflow.tasks.to_json,
       workflow.retirement.to_json,
       workflow.aggregation.to_json ]
  end

  let(:header) do
    %w(workflow_id display_name version active classifications_count pairwise grouped prioritized primary_language first_task tutorial_subject_id retired_set_member_subjects_count tasks retirement aggregation)
  end

  describe "::project_headers" do
    it 'should contain the required headers' do
      expect(described_class.project_headers).to match_array(header)
    end
  end

  describe "#to_array" do
    subject { described_class.new.to_array(workflow) }

    it { is_expected.to match_array(fields) }
  end
end
