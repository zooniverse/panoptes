# frozen_string_literal: true

require 'spec_helper'

describe WorkflowCloner do
  describe '#dup', :focus do
    let(:workflow) { create(:workflow) }
    let(:target_project) { create(:project) }
    let(:copier) { target_project.user }
    let(:workflow_translation) do
      create(:workflow_translation, translated: workflow) do |translation|
        translated_strings = TranslationStrings.new(workflow).extract
        translation.update_strings_and_versions(translated_strings, workflow.latest_version_id)
      end
    end
    let(:copied_workflow) { described_class.dup(workflow.id, target_project.id) }

    it 'returns an unsaved workflow' do
      expect(copied_workflow.persisted?).to be false
    end

    it 'returns a valid workflow' do
      expect(copied_workflow).to be_valid
    end

    it 'adds a copy suffix to the display_name' do
      expect(copied_workflow.display_name).to include("#{workflow.display_name} (copy:")
    end

    it 'copies existing attributes' do
      %i[tasks primary_language pairwise grouped prioritized first_task retirement subject_selection_strategy mobile_friendly strings steps].each do |attribute|
        expect(copied_workflow.send(attribute)).to eq(workflow.send(attribute))
      end
    end

    it 'sets the workflow to inactive to avoid releasing these on live projects' do
      expect(copied_workflow.active).to be false
    end

    it 'resets the finished_at to nil' do
      expect(copied_workflow.finished_at).to be_nil
    end

    it 'resets the completeness to 0' do
      expect(copied_workflow.completeness).to eq(0.0)
    end

    it 'resets the activity to 0' do
      expect(copied_workflow.activity).to eq(0)
    end

    it 'ensures the workflow serializes with the project' do
      expect(copied_workflow.serialize_with_project).to eq(true)
    end

    it 'resets the workflow classifications_count to 0' do
      expect(copied_workflow.classifications_count).to eq(0)
    end

    it 'resets the workflow real_set_member_subjects_count to 0' do
      expect(copied_workflow.real_set_member_subjects_count).to eq(0)
    end

    it 'does not copy the linked subject sets' do
      expect(copied_workflow.subject_sets).to be_empty
    end

    it 'resets the workflow retired_set_member_subjects_count to 0' do
      expect(copied_workflow.retired_set_member_subjects_count).to eq(0)
    end

    it 'resets the workflow published_version_id to nil' do
      expect(copied_workflow.published_version_id).to be_nil
    end

    it 'adds the source workflow id to the copied workflows configuration' do
      expect(copied_workflow.configuration['source_workflow_id']).to be(workflow.id)
    end

    it 'has links the copied workflow to the target project' do
      expect(copied_workflow.project_id).to eq(target_project.id)
    end

    # how do we handle these version ones??
    # current_version_number
    # major_version
    # minor_version

    #   it 'correctly sets the string versions to the newly minted copied project version ids' do
    #     translation_string_version_ids = copied_project.translations.map { |tr| tr.string_versions.values }.flatten.uniq
    #     expect(translation_string_version_ids).to match([copied_project.latest_version_id])
    #   end
    # end
  end
end
