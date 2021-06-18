# frozen_string_literal: true

require 'spec_helper'

describe WorkflowCopier do
  let(:workflow) { create(:workflow) }
  let(:target_project) { create(:project) }
  let(:copier) { target_project.user }
  let(:copied_workflow) { described_class.copy(workflow, target_project.id) }

  describe '#copy_by_id' do
    it 'find the workflow and uses the .copy method' do
      allow(Workflow).to receive(:find).and_return(workflow)
      allow(WorkflowCopier).to receive(:copy)
      described_class.copy_by_id(workflow.id, target_project.id)
      expect(WorkflowCopier).to have_received(:copy).with(workflow, target_project.id)
    end
  end

  describe '#copy' do
    it 'returns a valid workflow' do
      expect(copied_workflow).to be_valid
    end

    it 'returns an saved workflow' do
      expect(copied_workflow.persisted?).to be(true)
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
      expect(copied_workflow.active).to be(false)
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

    it 'links the copied workflow to the target project' do
      expect(copied_workflow.project_id).to eq(target_project.id)
    end

    it 'resets the current_version_number' do
      expect(copied_workflow.current_version_number).to be_nil
    end

    it 'resets the major version number to 1' do
      expect(copied_workflow.major_version).to eq(1)
    end

    it 'resets the minor version number to 1' do
      expect(copied_workflow.minor_version).to eq(1)
    end

    it 'creates new non copied worklfow_versions association records' do
      expect(copied_workflow.workflow_versions.pluck(:id)).not_to match(workflow.workflow_versions.pluck(:id))
    end

    context 'when a workflow has translations' do
      let(:translated_display_name) { 'another language string here' }

      before do
        create(:workflow_translation, translated: workflow) do |translation|
          translated_strings = TranslationStrings.new(workflow).extract
          translated_strings['display_name'] = translated_display_name
          translation.update_strings_and_versions(translated_strings, workflow.latest_version_id)
          translation.save!
        end
      end

      it 'correctly sets the latest_workflow_id' do
        expect(copied_workflow.latest_version_id).not_to be_nil
      end

      it 'persists the translations' do
        expect(copied_workflow.translations.first.persisted?).to be(true)
      end

      it 'preserves the translated strings' do
        copied_translation_display_name = copied_workflow.translations.first.strings['display_name']
        expect(copied_translation_display_name).to eq(translated_display_name)
      end

      it 'correctly sets the string versions to the newly minted copied project version ids' do
        translation_string_version_ids = copied_workflow.translations.map { |tr| tr.string_versions.values }.flatten.uniq
        expect(translation_string_version_ids).to match([copied_workflow.latest_version_id])
      end
    end
  end
end
