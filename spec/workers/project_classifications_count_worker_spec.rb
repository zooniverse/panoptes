require 'spec_helper'

RSpec.describe ProjectClassificationsCountWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }

  let!(:swc) do
    create :subject_workflow_count, subject: subject, workflow: workflow, classifications_count: 5
  end

  describe "#perform" do
    it 'updates the project counter' do
      expect { worker.perform(project.id) }
        .to change { project.reload.classifications_count }
        .from(0).to(5)
    end

    it 'updates the workflow counter' do
      expect { worker.perform(project.id) }
        .to change { workflow.reload.classifications_count }
        .from(0).to(5)
    end
  end
end
