require "spec_helper"

RSpec.describe SubjectSetSubjectCounterWorker do
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject_set) { workflow.subject_sets.first }

  describe "#perform" do
    it "should update the set count with the number of linked subjects" do
      expect_any_instance_of(SubjectSet)
        .to receive(:update_column)
        .with(:set_member_subjects_count, subject_set.set_member_subjects.count)
      expect_any_instance_of(SubjectSet)
        .to receive(:touch)
      described_class.new.perform(subject_set.id)
    end

    it "should call a workflow subjects count worker" do
      subject_set.workflow_ids.each do |workflow_id|
        expect(WorkflowSubjectsCountWorker)
          .to receive(:perform_async)
          .with(workflow_id)
      end
      described_class.new.perform(subject_set.id)
    end
  end
end
