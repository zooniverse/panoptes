require 'spec_helper'

RSpec.describe TranslationSyncWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }

  describe "#perform" do
    it "should create a new translation resource" do
      expect {
        worker.perform(project.class.to_s, project.id, project.primary_language)
      }.to change {
        Translation.count
      }.by(1)
    end

    context "with an existing translation" do
      let(:translation) do
        create(:translation, translated: project, language: project.primary_language)
      end
      let(:project_contents) { project.project_contents }
      let(:new_title) { "freshly translated for you" }

      it "should update the translation strings for the supplied resource" do
        old_title = translation.strings["title"]
        project_contents.update_column(:title, new_title)
        expect {
          worker.perform(project.class.to_s, project.id, project.primary_language)
        }.to change {
          translation.reload.strings["title"]
        }.from(old_title).to(new_title)
      end
    end
  end
end
