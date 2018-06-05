require 'spec_helper'

describe CalculateProjectCompletenessWorker do
  let(:worker) { described_class.new }
  let(:project) { create :project }


  it "should fail quickly when it can't find the project" do
    expect(Project).not_to receive(:transaction)
    worker.perform("-1")
  end

  describe '#project_completeness' do
    let(:project) do
      double(
        active_workflows: [ double(completeness: 1), double(completeness: 0) ]
      )
    end
    before do
      allow(worker).to receive(:project).and_return(project)
    end

    it 'returns the average of the workflow completenesses' do
      expect(worker.project_completeness).to eq(0.5)
    end

    context "when a project has no active workflows" do
      it "should set to 0.0" do
        allow(project).to receive(:active_workflows).and_return([])
        expect(worker.project_completeness).to eq(0.0)
      end
    end
  end

  describe '#workflow_completeness' do
    let(:subject_set) { create(:subject_set_with_subjects) }
    let(:workflow) do
      create :workflow, subject_sets: [subject_set], retirement: {'criteria' => 'classification_count', 'options' => {'count' => 10}}
    end

    shared_examples "it reports completeness correctly" do

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

    it 'returns 0 when no subjects are linked' do
      allow(workflow).to receive(:subjects_count).and_return(0)
      expect(worker.workflow_completeness(workflow)).to eq(0.0)
    end

    context 'classification count retirement' do
      it_should_behave_like "it reports completeness correctly"
    end

    context 'no panoptes retirement' do
      before do
        workflow.retirement = {'criteria' => 'never_retire', 'options' => {}}
      end

      it_should_behave_like "it reports completeness correctly"
    end
  end

  describe "project state transitions" do
    before do
      allow(Project).to receive(:find).and_return(project)
    end

    context "when the project is not complete" do
      before do
        allow(project)
        .to receive(:active_workflows)
        .and_return([double(completeness: 0.91)])
      end

      it "should not move the project to paused" do
        expect {
          worker.perform(project)
        }.not_to change {
          project.state
        }
      end

      it "should move a paused project to active" do
        project.paused!
        expect {
          worker.perform(project)
        }.to change {
          project.reload.attributes["state"]
        }.to(nil)
      end

      it "should not move an active project to active" do
        expect {
          worker.perform(project)
        }.not_to change {
          project.state
        }
      end

      context "with a finished project" do
        before do
          project.finished!
        end

        it "should not move to active" do
          expect {
            worker.perform(project)
          }.not_to change {
            project.state
          }
        end

        it "should not move a complete project to paused" do
          allow(worker).to receive(:project_completeness).and_return(1.0)
          expect {
            worker.perform(project)
          }.not_to change {
            project.state
          }
        end
      end
    end

    context "when the project is active and complete" do
      before do
        allow(project)
        .to receive(:active_workflows)
        .and_return([double(completeness: 1)])
      end

      it "should move it to paused" do
        expect {
          worker.perform(project)
        }.to change {
          project.state
        }.to("paused")
      end
    end
  end

  describe "project touch timestamp" do
    before do
      allow(Project).to receive(:find).and_return(project)
    end

    it "should touch the project timestamp on update" do
      expect(project).to receive(:touch).once
      worker.perform(project)
    end
  end
end
