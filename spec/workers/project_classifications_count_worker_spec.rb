require 'spec_helper'

RSpec.describe ProjectClassificationsCountWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) do
    create(:subject,
      project: project,
      subject_sets: [create(:subject_set, workflows: [workflow])]
    )
  end
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

    context "when the project has launch date" do
      let(:another_subject) do
        create(:subject,
          project: project,
          subject_sets: [create(:subject_set, workflows: [workflow])]
        )
      end
      let(:another_swc) do
        create(:subject_workflow_count,
          subject: another_subject,
          workflow: workflow,
          classifications_count: 2
        )
      end

      it 'should respect the launch_date in the count' do
        project.update_column(:launch_date, DateTime.now)
        another_swc
        expect { worker.perform(project.id) }
          .to change { workflow.reload.classifications_count }
          .from(0).to(2)
      end
    end
  end
end
