require 'spec_helper'

describe CalculateProjectActivityWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:user) { project.user }
  let(:in_period_classifications) do
    create_list(:classification, 2, project: project, workflow: workflow)
  end
  let(:non_normal_period_classification) do
    c = create(:classification, project: project, workflow: workflow)
    c.update_column(:created_at, 25.hours.ago)
    c
  end
  let(:classifications) do
    [ non_normal_period_classification, in_period_classifications ].flatten
  end

  describe '#perform' do
    context "when it can't find the project" do
      it "should fail quickly" do
        expect(Project).not_to receive(:transaction)
        worker.perform("-1")
      end
    end

    context "with classifications and the tracked activity classification id" do
      before do
        classifications
        workflow.update_column(:activity_classification_id, 1)
      end
      let(:activity_count) { 2 }

      it 'should update the workflow activity attributes' do
        expect_any_instance_of(Workflow)
          .to receive(:update_columns)
          .with({
            activity: activity_count,
            activity_classification_id: in_period_classifications.first.id
          })
        worker.perform(project.id)
      end

      it 'should update the project activity attributes' do
        expect_any_instance_of(Project)
          .to receive(:update_columns)
          .with({activity: activity_count})
        worker.perform(project.id)
      end

      context "with a longer activity period" do
        it 'should have different counts and track a different activity classification' do
          expect_any_instance_of(Workflow)
            .to receive(:update_columns)
            .with({
              activity: 3,
              activity_classification_id: non_normal_period_classification.id
            })
          worker.perform(project.id, 48.hours.ago)
        end
      end
    end
  end

  describe CalculateProjectActivityWorker::WorkflowActivityPeriod do
    let(:period) do
      CalculateProjectActivityWorker::WorkflowActivityPeriod::ACTIVITY_PERIOD
    end
    subject { described_class.new(workflow, period) }

    it 'returns 0 when no classifications have been made yet' do
      expect(subject.count).to eq(0)
    end

    context "with classifications and the tracked activity classification id" do
      before do
        classifications
        workflow.update_column(:activity_classification_id, 1)
      end

      it 'should only count classification in last 24 hours' do
        expect(subject.count).to eq(2)
      end

      context "with a longer activity period" do
        let(:period) { 48.hours.ago }

        it 'should only count classification in last 48 hours' do
          expect(subject.count).to eq(3)
        end
      end

      context "with a later activity_classification_id" do
        it 'should only count the classifications after the id' do
          id = in_period_classifications.first.id
          workflow.update_column(:activity_classification_id, id)
          expect(subject.count).to eq(1)
        end

        it 'should only count the classifications after the id' do
          id = in_period_classifications.last.id
          workflow.update_column(:activity_classification_id, id)
          expect(subject.count).to eq(0)
        end
      end
    end
  end
end
