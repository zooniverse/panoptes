require 'spec_helper'

describe WorkflowCounter do
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:counter) { WorkflowCounter.new(workflow) }

  describe 'classifications' do
    let(:now) { DateTime.now.utc }

    it "should return 0 if there are none" do
      expect(counter.classifications).to eq(0)
    end

    context "with classifications" do
      before do
        workflow.subjects.each do |subject|
          create(:subject_workflow_status, workflow: workflow, subject: subject, classifications_count: 1)
        end
      end

      it "should return 2" do
        expect(counter.classifications).to eq(2)
      end
    end
  end
end
