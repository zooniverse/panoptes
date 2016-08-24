require 'spec_helper'

describe SubjectWorkflowCounter do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:swc) do
    create(:subject_workflow_count, workflow: workflow, classifications_count: 0)
  end
  let(:counter) { SubjectWorkflowCounter.new(swc) }

  describe 'classifications' do
    let(:now) { DateTime.now.utc }

    it "should return 0 if there are none" do
      expect(counter.classifications).to eq(0)
    end

    context "with classifications" do
      before do
        2.times do
          c = create(:classification,  subject_ids: [swc.subject_id], project: project, workflow: workflow)
          create(:user_project_preference, project: project, user: c.user)
        end
      end

      it "should return 2" do
        expect(counter.classifications).to eq(2)
      end

      it "should respect the project launch date" do
        allow(project).to receive(:launch_date).and_return(now)
        expect(counter.classifications).to eq(0)
        allow(project).to receive(:launch_date).and_return(now-1.day)
        expect(counter.classifications).to eq(2)
      end
    end
  end
end
