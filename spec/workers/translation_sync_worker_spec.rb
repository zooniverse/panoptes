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

      it 'updates strings if workflow has no versions yet' do
        workflow = create :workflow
        translation = create :translation, translated: workflow
        old_string = translation.strings["tasks.shape.question"]
        workflow.primary_content.strings["shape.question"] = "asdf"
        workflow.save!
        workflow.workflow_versions.delete_all

        expect {
          worker.perform(workflow.class.to_s, workflow.id, workflow.primary_language)
        }.to change {
          translation.reload.strings["tasks.shape.question"]
        }.from(old_string).to("asdf")
      end
    end
  end
end
