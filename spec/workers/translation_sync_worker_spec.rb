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
      let(:primary_content) { project.primary_content }
      let(:new_title) { "freshly translated for you" }

      it "should update the translation strings for the supplied resource" do
        old_title = translation.strings["title"]
        primary_content.update_column(:title, new_title)
        expect {
          worker.perform(project.class.to_s, project.id, project.primary_language)
        }.to change {
          translation.reload.strings["title"]
        }.from(old_title).to(new_title)
      end
    end

    # TODO: this should sync all the related resources for a project.
    # do we wrap this in a long running transaction?
    # or do we fire a bunch of workers for each type of resource?
    # prefer the latter version ^ use concurrency like a boss
    # project - ✓
    # project.workflows - ✓
    # project.pages -
    # project.field_guides -
    # project.tutorials -
    # orgs?
  end
end
