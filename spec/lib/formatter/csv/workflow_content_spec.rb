require "spec_helper"

RSpec.describe Formatter::Csv::WorkflowContent do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:workflow_content) { workflow.content_for(workflow.primary_language) }
  let(:wc_version) { workflow_content }

  let(:fields) do
    [  wc_version.id,
       wc_version.workflow.id,
       wc_version.language,
       ModelVersion.version_number(wc_version),
       wc_version.strings.to_json ]
  end

  let(:header) do
    %w(workflow_content_id workflow_id language version strings)
  end

  describe "::workflow_contents_headers" do
    it 'should contain the required headers' do
      expect(described_class.headers).to match_array(header)
    end
  end

  describe "#to_array" do
    subject { described_class.new.to_array(wc_version) }

    it { is_expected.to match_array(fields) }
  end

  context "with a versioned workflow content" do

    with_versioning do
      let(:q_workflow) { build(:question_task_workflow) }
      let(:strings) { q_workflow.workflow_contents.first.strings }

      before(:each) do
        workflow.workflow_contents.first.update(strings: strings)
      end

      describe "#to_array on the latest version" do
        subject { described_class.new.to_array(wc_version) }

        it { is_expected.to match_array(fields) }
      end

      describe "#to_array on the previous version" do
        let(:wc_version) { workflow_content.previous_version }
        subject { described_class.new.to_array(wc_version) }

        it { is_expected.to match_array(fields) }
      end
    end
  end
end
