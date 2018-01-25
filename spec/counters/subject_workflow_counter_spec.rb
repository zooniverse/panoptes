require 'spec_helper'

describe SubjectWorkflowCounter do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:sws) do
    create(:subject_workflow_status, workflow: workflow, classifications_count: 0)
  end
  let(:counter) { SubjectWorkflowCounter.new(sws) }

  describe 'classifications' do
    let(:now) { DateTime.now.utc }

    it "should return 0 if there are none" do
      expect(counter.classifications).to eq(0)
    end

    context "with classifications" do
      before do
        2.times do
          create(:classification,
            subject_ids: [sws.subject_id],
            project: project,
            workflow: workflow
          )
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

      it "should ignore any incomplete classifications" do
        incomplete = create(:classification,
          subject_ids: [sws.subject_id],
          project: project,
          workflow: workflow,
          completed: false
        )
        expect(counter.classifications).to eq(2)
      end

      context "when the subject is classified for other workflows" do
        let(:another_workflow) { create(:workflow, project: project) }

        it "should still only count 2" do
          create(:classification, subject_ids: [sws.subject_id], project: project, workflow: another_workflow)
          expect(counter.classifications).to eq(2)
        end
      end
    end
  end
end
