# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Formatter::Csv::V2::DropdownAnnotation do
  # details on what allowCreate wf task values for dropdowns do
  # and how that relates to the annotaion value `option: false`
  # https://github.com/zooniverse/caesar/pull/842#issuecomment-499586993
  let(:workflow) { build_stubbed(:workflow, :dropdown_simple) }
  let(:task_info) { workflow.tasks['T1'] }
  let(:workflow_information) { instance_double(Formatter::Csv::WorkflowInformation) }
  let(:annotation) do
    {
      'task' => 'T1',
      # Note: the selected value is not index based (similar to single / simple tasks)
      # and not the old PFE value key. See details at
      # https://github.com/zooniverse/front-end-monorepo/discussions/2131
      'value' => { 'selection' => 2, 'option' => true },
      'taskType' => 'dropdown-simple'
    }
  end
  let(:results) do
    {
      'task' => 'T1',
      'task_type' => 'dropdown-simple',
      'value' => {
        'select_label' => 'Country',
        'option' => true,
        'value' => 2,
        'label' => 'US'
      }
    }
  end
  let(:dropdown_annotation) { described_class.new(task_info, annotation, workflow_information) }

  before do
    string_key = 'T1.selects.0.options.*.2.label'
    string_value = workflow.strings[string_key]
    allow(workflow_information).to receive(:string).with(string_key).and_return(string_value)
  end

  it 'adds the correct answer labels' do
    formatted_results = dropdown_annotation.format
    expect(formatted_results).to eq(results)
  end

  context 'with missing value JSON (nil value)' do
    let(:annotation) do
      { 'task' => 'T1', 'value' => nil, 'taskType' => 'dropdown-simple' }
    end
    let(:results) do
      {
        'task' => 'T1',
        'task_type' => 'dropdown-simple',
        'value' => { 'select_label' => 'Country' }
      }
    end

    it 'adds the select label without failing' do
      formatted_results = dropdown_annotation.format
      expect(formatted_results).to eq(results)
    end
  end

  # for the case where a FEM annotation for a dropdown-simple
  # resolves to a workflow task that has multiple selects in PFE
  # this should never happen based on the wiring in FEM but best to raise here in case
  # https://github.com/zooniverse/front-end-monorepo/tree/master/packages/lib-classifier/src/plugins/tasks/SimpleDropdownTask/models/helpers/legacyDropdownAdapter
  # https://github.com/zooniverse/front-end-monorepo/blob/master/docs/arch/adr-30.md#consequences
  context 'with a task that has multiple selects (dropdowns) but an annotation with dropdown-simple' do
    let(:workflow) { build_stubbed(:workflow, :complex_task) }
    let(:task_info) { workflow.tasks['T7'] }
    let(:annotation) do
      {
        'task' => 'T7',
        'value' => { 'selection' => '3844fc24a3df7', 'option' => true, 'taskType' => 'dropdown-simple' }
      }
    end

    it 'raises an error and stops processing' do
      expect { dropdown_annotation.format }.to raise_error(
        Formatter::Csv::V2::DropdownAnnotation::TaskError,
        'Dropdown task has multiple selects and is not conformant to v2 dropdown-simple task type - aborting'
      )
    end
  end

  # for the case where a FEM annotation for a dropdown-simple
  # but with a workflow that allows for use supplied values
  # technically disabled right now but may be enabled in the future
  # https://github.com/zooniverse/front-end-monorepo/blob/582e6e48181d814f529d2c34e6969641cb5cbbeb/packages/lib-classifier/src/plugins/tasks/SimpleDropdownTask/README.md#dev-notes
  context 'with a task that allows user provided values' do
    let(:workflow) do
      build_stubbed(:workflow, :dropdown_simple) do |w|
        # update the simple dropdown task to allow user supplied values
        w.tasks['T1']['selects'][0]['allowCreate'] = true
      end
    end
    let(:task_info) { workflow.tasks['T1'] }
    let(:annotation) do
      {
        'task' => 'T1',
        'value' => { 'selection' => 'Hey! Listen!', 'option' => false },
        'taskType' => 'dropdown-simple'
      }
    end
    let(:results) do
      {
        'task' => 'T1',
        'task_type' => 'dropdown-simple',
        'value' => {
          'select_label' => 'Country',
          'option' => false,
          'value' => 'Hey! Listen!'
        }
      }
    end

    it 'adds the user supplied label correctly' do
      formatted_results = dropdown_annotation.format
      expect(formatted_results).to eq(results)
    end
  end
end
