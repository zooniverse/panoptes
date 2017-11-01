require 'spec_helper'

describe WorkflowCounter do
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:counter) { WorkflowCounter.new(workflow) }

  describe 'classifications' do

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

      context "when unlinking subject_sets" do
        let(:workflow) { create(:workflow_with_subjects, num_sets: 2) }

        it "should only return the count for the linked sets" do
          set_to_keep = workflow.subject_sets.sample
          workflow.subject_sets = [ set_to_keep ]
          expect(counter.classifications).to eq(2)
        end
      end
    end
  end

  describe 'retired subjects' do

    it "should return 0 if there are none" do
      expect(counter.retired_subjects).to eq(0)
    end

    context "with workflow counts" do
      let(:sws_params) do
        { workflow: workflow, retired_at: DateTime.now, created_at: DateTime.now + 2.days }
      end

      before do
        workflow.subjects.each do |subject|
          create(:subject_workflow_status, sws_params.merge(subject: subject))
        end
      end

      it "should return 2" do
        expect(counter.retired_subjects).to eq(2)
      end

      it "should ignore the project launch date" do
        workflow.project.update_column(:launch_date, DateTime.now + 1.day)
        expect(counter.retired_subjects).to eq(2)
      end

      it "should return 0 when a subject set was unlinked" do
        workflow.subject_sets = []
        expect(counter.retired_subjects).to eq(0)
      end
    end
  end
end
