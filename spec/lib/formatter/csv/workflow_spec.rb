require "spec_helper"

RSpec.describe Formatter::Csv::Workflow do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:workflow_version) { workflow }

  def retirement_json
    ::Workflow::DEFAULT_RETIREMENT_OPTIONS.to_json
  end

  let(:fields) do
    [  workflow_version.id,
       workflow_version.display_name,
       ModelVersion.version_number(workflow_version),
       workflow_version.active,
       workflow_version.classifications_count,
       workflow_version.pairwise,
       workflow_version.grouped,
       workflow_version.prioritized,
       workflow_version.primary_language,
       workflow_version.first_task,
       workflow_version.tutorial_subject_id,
       workflow_version.retired_set_member_subjects_count,
       workflow_version.tasks.to_json,
       retirement_json,
       workflow_version.aggregation.to_json ]
  end

  let(:header) do
    %w(workflow_id display_name version active classifications_count pairwise grouped prioritized primary_language first_task tutorial_subject_id retired_set_member_subjects_count tasks retirement aggregation)
  end

  describe "::workflow_headers" do
    it 'should contain the required headers' do
      expect(described_class.headers).to match_array(header)
    end
  end

  describe "#to_array" do
    subject { described_class.new.to_array(workflow_version) }

    it { is_expected.to match_array(fields) }
  end

  context "with a versioned workflow" do

    with_versioning do
      let(:q_workflow) { build(:question_task_workflow) }
      let(:tasks) { q_workflow.tasks }

      before(:each) do
        updates = {
          tasks: tasks, pairwise: !workflow.pairwise,
          grouped: !workflow.grouped, prioritized: !workflow.prioritized
        }
        workflow.update_attributes(updates)
      end

      describe "#to_array on the latest version" do
        subject { described_class.new.to_array(workflow) }

        it { is_expected.to match_array(fields) }
      end

      describe "#to_array on the previous version" do
        let(:workflow_version) { workflow.previous_version }

        subject { described_class.new.to_array(workflow_version) }

        it { is_expected.to match_array(fields) }
      end
    end
  end
end
