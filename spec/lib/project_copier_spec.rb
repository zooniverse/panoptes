require 'spec_helper'

describe ProjectCopier do
  describe '#copy' do
    let(:project) { create(:full_project) }
    let(:copyist) { create(:user) }
    let(:copied_project) { described_class.new(project.id, copyist.id).copy }

    it 'returns a valid project' do
      expect(described_class.new(project.id, copyist.id).copy).to be_valid
    end

    it 'sets the owner to the api_user' do
      expect(copied_project.owner).to eq(copyist)
    end

    it 'renames a project when the owner is copying their own project' do
      new_copy = described_class.new(project.id, project.owner.id).copy
      expect(new_copy.display_name).to include('(copy)')
    end

    it 'has matching attributes' do
      expect(copied_project.display_name).to eq(project.display_name)
    end

    it 'resets the live attribute' do
      expect(copied_project.live).to be false
    end

    it 'resets the launch_approved attribute' do
      expect(copied_project.launch_approved).to be false
    end

    it 'strips the template config' do
      expect(copied_project.configuration).not_to include(:template)
    end

    it "adds the source project id to the copied project's configuration" do
      expect(copied_project.configuration['source_project_id']).to be(project.id)
    end

    context 'when a project has active_worklfows' do
      it 'creates a valid workflow copy' do
        expect(copied_project.active_workflows.first).to be_valid
      end

      it 'copies the workflow display_name' do
        expect(copied_project.active_workflows.first.display_name).to eq(project.active_workflows.first.display_name)
      end

      it 'creates a primary language translation resource for the workflow' do
        active_workflow = copied_project.active_workflows.first
        expect(active_workflow.translations.first.language).to eq(project.primary_language)
      end
    end

    context "when a project's active_workflow has a tutorial" do
      before do
        create(:tutorial, project: project, workflows: [project.active_workflows.first])
      end

      it 'creates a primary language translation resource for the tutorial' do
        active_workflow = copied_project.active_workflows.first
        tutorial = active_workflow.tutorials.first
        expect(tutorial.translations.first.language).to eq(project.primary_language)
      end
    end

    context 'when a project has tags' do
      it 'is a valid record' do
        create(:tag, resource: project)
        expect(copied_project.tags.first).to be_valid
      end
    end

    context 'when a project has field_guides' do
      it 'is a valid record' do
        create(:field_guide, project: project)
        expect(copied_project.field_guides.first).to be_valid
      end

      it 'creates a primary language translation resource for the field_guide' do
        create(:field_guide, project: project)
        field_guide = copied_project.field_guides.first
        expect(field_guide.translations.first.language).to eq(project.primary_language)
      end
    end

    context 'when a project has a project page' do
      it 'is a valid record' do
        create(:project_page, project: project)
        expect(copied_project.pages.first).to be_valid
      end

      it 'creates a primary language translation resource for the page' do
        create(:project_page, project: project)
        page = copied_project.pages.first
        expect(page.translations.first.language).to eq(project.primary_language)
      end
    end

    context 'when a project has translations' do
      let(:translated_display_name) { 'another language string here' }

      before do
        build(:project_translation, translated: project) do |translation|
          translated_strings = TranslationStrings.new(project).extract
          translated_strings['display_name'] = translated_display_name
          translation.update_strings_and_versions(translated_strings, project.latest_version_id)
          translation.save!
        end
      end

      it 'correctly sets the latest_version_id' do
        expect(copied_project.latest_version_id).not_to be_nil
      end

      it 'persists the translations' do
        expect(copied_project.translations.first.persisted?).to be(true)
      end

      it 'preserves the translated strings' do
        copied_translation_display_name = copied_project.translations.first.strings['display_name']
        expect(copied_translation_display_name).to eq(translated_display_name)
      end

      it 'correctly sets the string versions to the newly minted copied project version ids' do
        translation_string_version_ids = copied_project.translations.map { |tr| tr.string_versions.values }.flatten.uniq
        expect(translation_string_version_ids).to match([copied_project.latest_version_id])
      end
    end
  end
end
