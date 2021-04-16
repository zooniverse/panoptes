# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Formatter::Csv::AnnotationV2ForCsv do
  let(:workflow_version) { build_stubbed(:workflow_version, workflow: workflow, tasks: workflow.tasks, strings: workflow.strings) }
  let(:cache) { instance_double('ClassificationDumpCache') }

  context 'with a v2 dropdown (simple) task' do
    let(:workflow) { build_stubbed(:workflow, :dropdown_simple) }
    let(:annotation) do
      {
        'task' => 'T1',
        'value' => { 'selection' => '3844fc24a3df7', 'option' => true, 'taskType' => 'dropdown-simple' }
      }
    end

    let(:classification) do
      build_stubbed(:classification, subjects: [], workflow: workflow, annotations: [annotation])
    end

    let(:results) do
      {
        'task' => 'T1',
        'value' => {
          'select_label' => 'Country',
          'option' => true,
          'value' => '3844fc24a3df7',
          'label' => 'US'
        }
      }
    end

    before do
      maj, min = classification.workflow_version.split('.').map(&:to_i)
      allow(cache).to receive(:workflow_at_version).with(workflow, maj, min).and_return(workflow_version)
    end

    it 'adds the correct answer labels' do
      formatted = described_class.new(classification, classification.annotations[0], cache).to_h
      expect(formatted).to eq(results)
    end

    context 'with a nil value in the annotation' do
      let(:annotation) do
        { 'task' => 'T1', 'value' => nil, 'taskType' => 'dropdown-simple' }
      end
      let(:results) do
        {
          'task' => 'T1',
          'value' => { 'select_label' => 'Country' }
        }
      end

      it 'adds the select label without failing' do
        formatted = described_class.new(classification, classification.annotations[0], cache).to_h
        expect(formatted).to eq(results)
      end
    end

    # for the case where a FEM annotation for a dropdown-simple
    # resolves to a workflow task that has multiple selects in PFE
    # this should never happen based on the wiring in FEM but best to raise here in case
    # https://github.com/zooniverse/front-end-monorepo/tree/master/packages/lib-classifier/src/plugins/tasks/SimpleDropdownTask/models/helpers/legacyDropdownAdapter
    # https://github.com/zooniverse/front-end-monorepo/blob/master/docs/arch/adr-30.md#consequences
    context 'with a task that has multiple selects (dropdowns) but an annotation with dropdown-simple' do
      let(:workflow) { build_stubbed(:workflow, :complex_task) }
      let(:annotation) do
        {
          'task' => 'T7',
          'value' => { 'selection' => '3844fc24a3df7', 'option' => true, 'taskType' => 'dropdown-simple' }
        }
      end

      it 'raises an error and stops processing' do
        formatter = described_class.new(classification, classification.annotations[0], cache)
        expect { formatter.to_h }.to raise_error(
          Formatter::Csv::AnnotationV2ForCsv::V2DropdownSimpleTaskError,
          'Dropdown task has multiple selects and is not conformant to v2 dropdown-simple task type - aborting'
        )
      end
    end
  end
end
