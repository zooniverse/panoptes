require 'spec_helper'

describe ProjectCopier do
  describe '#copy', :focus do
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

    it 'has updated attributes' do
      expect(copied_project.live).to be false
      expect(copied_project.launch_approved).to be false
    end

    it 'strips the template config' do
      expect(copied_project.configuration).not_to include(:template)
    end

    it "adds the source project id to the copied project's configuration" do
      expect(copied_project.configuration['source_project_id']).to be(project.id)
    end

    it 'has valid copied workflows' do
      expect(copied_project.workflows.first).to be_valid
      expect(copied_project.workflows.first.display_name).to eq(project.workflows.first.display_name)
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
    end

    context 'when a project has a project page' do
      it 'is a valid record' do
        create(:project_page, project: project)
        expect(copied_project.pages.first).to be_valid
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
