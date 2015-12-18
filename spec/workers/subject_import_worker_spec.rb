require "spec_helper"

RSpec.describe SubjectImportWorker do
  let(:user) { create :user }
  let(:project) { create :project, owner: user }
  let(:subject_set) { create(:subject_set, project: project, workflows: []) }

  subject(:worker) { SubjectImportWorker.new }

  before do
    allow(worker).to receive(:download_csv).with("a_csv_url").and_return(<<-CSV)
url,metadata1,metadata2
https://placekitten.com/200/300.jpg,small,cute
https://placekitten.com/400/900.jpg,large,cute
    CSV
  end

  describe "#perform" do
    it 'creates subjects for each line in the CSV' do
      worker.perform(project.id, user.id, subject_set.id, "a_csv_url")

      subject_set.reload

      expect(subject_set.subjects.count).to eq(2)
      expect(subject_set.set_member_subjects_count).to eq(2)
      expected_urls = subject_set.subjects.map {|i| i.locations.first.src }
      expect(expected_urls).to match_array([
        "https://placekitten.com/200/300.jpg",
        "https://placekitten.com/400/900.jpg"
      ])

      expect(subject_set.subjects.pluck(:metadata)).to match_array([
        {"metadata1" => "small", "metadata2" => "cute"},
        {"metadata1" => "large", "metadata2" => "cute"}
      ])
    end
  end
end
