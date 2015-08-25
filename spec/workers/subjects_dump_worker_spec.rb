require "spec_helper"

RSpec.describe SubjectsDumpWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let(:subject_set) { create(:subject_set, project: project)}
  let!(:subjects) { create_list(:set_member_subject, 5, subject_set: subject_set).map(&:subject) }

  describe "#perform" do
    it_behaves_like "dump worker", SubjectDataMailerWorker, "project_subjects_export" do
      let(:num_entries) { subjects.size + 1 }
    end
  end
end
