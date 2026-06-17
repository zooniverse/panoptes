# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Formatter::Csv::V2::DrawingAnnotation do
  let(:workflow_version) { build_stubbed(:workflow_version, workflow: workflow, tasks: workflow.tasks, strings: workflow.strings) }
  let(:workflow) { build_stubbed(:workflow) }
  let(:cache) { instance_double('ClassificationDumpCache') }
  let(:workflow_information) { Formatter::Csv::WorkflowInformation.new(cache, workflow, '1.1') }
  let(:task_info) { workflow_information.task('interest') }
  let(:annotation) do
    {
      'task' => 'interest',
      'value' => [
        { 'x' => 1, 'y' => 2, 'toolIndex' => 1 },
        { 'x' => 3, 'y' => 4, 'toolIndex' => 2 },
        { 'x' => 5, 'y' => 6, 'toolIndex' => 1 }
      ]
    }
  end

  before do
    allow(cache).to receive(:workflow_at_version).with(workflow, 1, 1).and_return(workflow_version)
  end

  it 'adds the task label' do
    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['task_label']).to eq('Draw a circle')
  end

  it 'adds the tool labels for drawing tasks', :aggregate_failures do
    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['value'][0]['tool_label']).to eq('Green')
    expect(formatted['value'][1]['tool_label']).to eq('Blue')
    expect(formatted['value'][2]['tool_label']).to eq('Green')
  end

  it 'has a nil label when the tool is not found in the workflow' do
    annotation['value'] = [{ 'x' => 1, 'y' => 2, 'toolIndex' => 1000 }]

    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['value'][0]['tool_label']).to be_nil
  end

  it 'adds the tool label when the tool index uses the previous snake-case key' do
    annotation['value'] = [{ 'x' => 1, 'y' => 2, 'tool_index' => 1 }]

    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['value'][0]['tool_label']).to eq('Green')
  end

  it 'has a nil label when the tool index is missing' do
    annotation['value'] = [{ 'x' => 1, 'y' => 2 }]

    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['value'][0]['tool_label']).to be_nil
  end

  it 'returns the raw value if it is in an unexpected format' do
    annotation['value'] = 0

    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['value']).to eq(Array.wrap(annotation['value']))
  end

  it 'returns an empty list of values when annotation itself has no value' do
    annotation.delete('value')

    formatted = described_class.new(task_info, annotation, workflow_information).format
    expect(formatted['value']).to be_empty
  end
end
