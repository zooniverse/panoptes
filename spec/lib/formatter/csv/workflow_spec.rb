require "spec_helper"

RSpec.describe Formatter::Csv::Workflow do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:workflow_version) { workflow }

  def retirement_json
    ::Workflow::DEFAULT_RETIREMENT_OPTIONS.to_json
  end

  let(:rows) do
    [
      [
        workflow_version.id,
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
        workflow_version.aggregation.to_json,
        workflow_version.strings.to_json
      ]
    ]
  end

  let(:header) do
    %w(workflow_id display_name version active classifications_count pairwise grouped prioritized primary_language first_task tutorial_subject_id retired_set_member_subjects_count tasks retirement aggregation strings)
  end

  describe "#headers" do
    it 'should contain the required headers' do
      expect(described_class.new.headers).to match_array(header)
    end
  end

  describe "#to_rows" do
    subject { described_class.new.to_rows(workflow_version) }

    it { is_expected.to match_array(rows) }
  end

  context "with a versioned workflow" do

    with_versioning do
      let(:q_workflow) { build(:workflow, :question_task) }
      let(:tasks) { q_workflow.tasks }

      before(:each) do
        updates = {
          tasks: tasks, pairwise: !workflow.pairwise,
          grouped: !workflow.grouped, prioritized: !workflow.prioritized
        }
        workflow.update_attributes(updates)
      end

      describe "#to_rows on the latest version" do
        subject { described_class.new.to_rows(workflow) }

        it { is_expected.to match_array(rows) }
      end

      describe "#to_rows on the previous version" do
        let(:workflow_version) { workflow.previous_version }

        subject { described_class.new.to_rows(workflow_version) }

        it { is_expected.to match_array(rows) }
      end
    end
  end
end
