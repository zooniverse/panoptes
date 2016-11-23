require "spec_helper"

RSpec.describe SubjectsDumpWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1, project: project) }
  let(:unlinked_subject_set) { create(:subject_set, project: project)}
  let!(:subjects) do
    create_list(:set_member_subject, 2, subject_set: unlinked_subject_set).map(&:subject)
  end
  let(:num_subjects) { unlinked_subject_set.subjects.count + workflow.subjects.count }

  describe "#perform" do
    it_behaves_like "dump worker", SubjectDataMailerWorker, "project_subjects_export" do
      let(:num_entries) { num_subjects + 1 }
    end
  end
end
