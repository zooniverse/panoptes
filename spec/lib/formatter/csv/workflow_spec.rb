# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Formatter::Csv::Workflow do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:workflow_version) { workflow.workflow_versions.first }

  def retirement_json
    ::Workflow::DEFAULT_RETIREMENT_OPTIONS.to_json
  end

  let(:rows) do
    [
      [
        workflow.id,
        workflow.display_name,
        workflow_version.major_number,
        workflow.active,
        workflow.classifications_count,
        workflow.pairwise,
        workflow.grouped,
        workflow.prioritized,
        workflow.primary_language,
        workflow_version.first_task,
        workflow.tutorial_subject_id,
        workflow.retired_set_member_subjects_count,
        workflow_version.tasks.to_json,
        retirement_json,
        workflow_version.strings.to_json,
        workflow_version.minor_number
      ]
    ]
  end

  let(:header) do
    %w[workflow_id display_name version minor_version active classifications_count pairwise grouped
       prioritized primary_language first_task tutorial_subject_id retired_set_member_subjects_count
       tasks retirement strings]
  end

  describe '#headers' do
    it 'contains the required headers' do
      expect(described_class.new.headers).to match_array(header)
    end
  end

  describe '#to_rows' do
    subject { described_class.new.to_rows(workflow_version) }

    it { is_expected.to match_array(rows) }
  end

  context 'with a versioned workflow' do
    let(:q_workflow) { build(:workflow, :question_task) }
    let(:tasks) { q_workflow.tasks }

    before(:each) do
      updates = {
        tasks: tasks, pairwise: !workflow.pairwise,
        grouped: !workflow.grouped, prioritized: !workflow.prioritized
      }
      workflow.update(updates)
    end

    describe '#to_rows on the latest version' do
      subject { described_class.new.to_rows(workflow_version) }

      it { is_expected.to match_array(rows) }
    end

    describe '#to_rows on the previous version' do
      let(:workflow_version) { workflow.workflow_versions.order(:created_at).first }

      subject { described_class.new.to_rows(workflow_version) }

      it { is_expected.to match_array(rows) }
    end
  end
end
