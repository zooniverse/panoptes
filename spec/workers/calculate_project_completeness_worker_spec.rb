require 'spec_helper'

describe CalculateProjectCompletenessWorker do
  let(:worker) { described_class.new }
  let(:project) { create :project }

  it "should fail quickly when it can't find the project" do
    expect(Project).not_to receive(:transaction)
    worker.perform("-1")
  end

  describe "perform" do
    let(:project) { create(:full_project) }
    let(:workflow) { project.workflows.first }
    before do
      workflow.update_column(:retired_set_member_subjects_count, 2)
    end

    it "should update the workflow completeness metric" do
      expect {
        worker.perform(project.id)
      }.to change {
        workflow.reload.completeness
      }.to(0.5)
    end

    it "should update the project completeness metric" do
      expect {
        worker.perform(project.id)
      }.to change {
        workflow.reload.completeness
      }.to(0.5)
    end
  end

  describe '#project_completeness' do
    let(:workflows_relation_double) do
      [
        build_stubbed(:workflow, completeness: 0, real_set_member_subjects_count: 0, retired_set_member_subjects_count: 0),
        build_stubbed(:workflow, completeness: 1, real_set_member_subjects_count: 10, retired_set_member_subjects_count: 10)
      ]
    end
    let(:project) do
      instance_double('Project', active_workflows: workflows_relation_double)
    end

    before do
      allow(worker).to receive(:project).and_return(project)
    end

    it 'returns the proportional workflow completenesses metric' do
      expect(worker.project_completeness).to eq(1.0)
    end

    it "should set to 0.0 when a project has no active workflows" do
      allow(project).to receive(:active_workflows).and_return([])
      expect(worker.project_completeness).to eq(0.0)
    end

    context 'when a project has active workflows with 0 completeness (no linked subjects)' do
      let(:workflows_relation_double) do
        [
          build_stubbed(:workflow, completeness: 0, real_set_member_subjects_count: 0, retired_set_member_subjects_count: 0),
          build_stubbed(:workflow, completeness: 0, real_set_member_subjects_count: 0, retired_set_member_subjects_count: 0)
        ]
      end

      it 'returns 0.0' do
        expect(worker.project_completeness).to eq(0.0)
      end
    end

    context 'when a project has active workflows and varied completeness metrics and subject proportions' do
      let(:workflows_relation_double) do
        [
          build_stubbed(:workflow, completeness: 0.5, real_set_member_subjects_count: 100, retired_set_member_subjects_count: 50),
          build_stubbed(:workflow, completeness: 0.9, real_set_member_subjects_count: 900, retired_set_member_subjects_count: 810)
        ]
      end

      it 'returns the proportional scaled completeness metric' do
        # small error with extra precision due to floating point math
        # 0.5 * (100 / 1000) + 0.9 * (900 / 1000)
        # 0.05 + 0.81
        expect(worker.project_completeness).to eq(0.86)
      end
    end

    context 'when a project has recurring proportional completeness (1/6)' do
      let(:workflows_relation_double) do
        Array.new(6) do |_|
          build_stubbed(:workflow, completeness: 1.0, real_set_member_subjects_count: 1, retired_set_member_subjects_count: 1)
        end
      end

      it 'returns the correct value without precision rounding errors' do
        # frogsong - recurring small values issue with this one
        # 6(1.0 * (1 / 6)) == 6(1/6) == 1.0
        expect(worker.project_completeness).to eq(1.0)
      end
    end

    context 'when a project has varying workflow completeness proportions of small' do
      # nest quest go sparrows - to_d rounding issue with this one
      # total_subjects = 128610
      let(:workflows_relation_double) do
        [12860, 12860, 12863, 12863, 12860, 12860, 12860, 12860, 12863, 10094, 2767].map do |retired_subjects|
          build_stubbed(:workflow, completeness: 1.0, real_set_member_subjects_count: retired_subjects, retired_set_member_subjects_count: retired_subjects)
        end
      end

      it 'returns the correct value without precision rounding errors' do
        expect(worker.project_completeness).to eq(1.0)
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
        workflow.real_set_member_subjects_count = 2
        expect(worker.workflow_completeness(workflow)).to eq(1.0)
      end

      it 'returns 0.5 when half of the subjects are retired' do
        workflow.retired_set_member_subjects_count = 1
        workflow.real_set_member_subjects_count = 2
        expect(worker.workflow_completeness(workflow)).to eq(0.5)
      end

      it 'returns 1.0 when there are more retired subjects than subjects' do
        workflow.retired_set_member_subjects_count = 3
        workflow.real_set_member_subjects_count = 2
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
          .and_return(
            [build_stubbed(:workflow, completeness: 0.91, real_set_member_subjects_count: 100, retired_set_member_subjects_count: 91)]
          )
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
          }.not_to(
            change { project.state }
          )
        end

        it "should not move a complete project to paused" do
          allow(worker).to receive(:project_completeness).and_return(1.0)
          expect {
            worker.perform(project)
          }.not_to(
            change { project.state }
          )
        end
      end
    end

    context "when the project is active and complete" do
      before do
        allow(project)
          .to receive(:active_workflows)
          .and_return([build_stubbed(:workflow, completeness: 1.0, real_set_member_subjects_count: 10, retired_set_member_subjects_count: 10)])
      end

      it "should move it to paused" do
        expect {
          worker.perform(project)
        }.to change {
          project.state
        }.to("paused")
      end
    end

    context 'when the project is active with no workflows' do
      before do
        allow(project).to receive(:active_workflows).and_return([])
      end

      it 'should move it to paused' do
        expect {
          worker.perform(project)
        }.to change {
          project.state
        }.to("paused")
      end
    end

    context 'when the project has active workflows 0.0 completeness(no linked subjects)' do
      let(:project) { create(:project_with_workflow) }

      it 'move the state attribute to paused' do
        expect {
          worker.perform(project)
        }.to change(project, :state).to('paused')
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
