require 'spec_helper'

describe CalculateProjectCompletenessWorker do
  let(:worker) { described_class.new }
  let(:project) { create :project }

  describe '#project_completeness' do
    it 'returns the average of the workflow completenesses' do
      project = double(active_workflows: [
        double(completeness: 1),
        double(completeness: 0)
      ])

      expect(worker.project_completeness(project)).to eq(0.5)
    end

    context "when it can't find the project" do
      it "should fail quickly" do
        expect(Project).not_to receive(:transaction)
        worker.perform("-1")
      end
    end
  end

  describe '#workflow_completeness' do
    let(:subject1) { create :subject }
    let(:subject2) { create :subject }
    let(:workflow) { create :workflow, subject_sets: [create(:subject_set, subjects: [subject1, subject2])], retirement: {'criteria' => 'classification_count', 'options' => {'count' => 10}} }

    it 'returns 0 when no classifications have been made yet' do
      expect(worker.workflow_completeness(workflow)).to eq(0.0)
    end

    context 'no panoptes retirement' do
      before do
        workflow.retirement = {'criteria' => 'never_retire', 'options' => {}}
      end

      it 'returns 1 when all the subjects of a workflow have been retired' do
        workflow.classifications_count = 20
        workflow.retired_set_member_subjects_count = 2
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end

      it 'returns 0.5 when half of the subjects are retired' do
        workflow.retired_set_member_subjects_count = 1
        expect(worker.workflow_completeness(workflow)).to eq(0.5)
      end

      it 'returns 1.0 when there are more retired subjects than subjects' do
        workflow.retired_set_member_subjects_count = 3
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end
    end

    context 'classification count retirement' do
      it 'returns 1 when all the subjects of a workflow have been retired' do
        workflow.classifications_count = 20
        workflow.retired_set_member_subjects_count = 2
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end

      it 'returns 0.5 when all subjects are halfway towards their retirement limit' do
        workflow.classifications_count = 10
        expect(worker.workflow_completeness(workflow)).to eq(0.5)
      end

      it 'returns 1.0 when there are more classifications than needed and everything is retired' do
        workflow.classifications_count = 9001
        workflow.retired_set_member_subjects_count = 2
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end
    end
  end
end
