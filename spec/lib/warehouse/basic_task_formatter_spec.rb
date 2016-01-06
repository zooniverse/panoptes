require 'spec_helper'

RSpec.describe Warehouse::BasicTaskFormatter do
  let(:workflow)       { build_stubbed(:workflow, project: nil) }
  let(:contents)       { build_stubbed(:workflow_content, workflow: nil) }
  let(:classification) { build_stubbed(:classification, subjects: []) }
  let(:definition)     { workflow.tasks["interest"] }

  let(:formatted) do
    described_class.new(task_definition: definition, translations: contents.strings).format(annotation)
  end

  context 'for a known task' do
    let(:annotation) do
      {
        "task" => "interest",
        "value" => [{"x"=>1, "y"=>2, "tool"=>1}, {"x"=>3, "y"=>4, "tool"=>2}, {"x"=>5, "y"=>6, "tool"=>1}]
      }
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[:task]).to eq(annotation["task"])
      expect(formatted[:task_label]).to eq("Draw a circle")
      expect(formatted[:task_type]).to eq("drawing")
      expect(formatted[:value]).to eq(annotation.to_json)
    end
  end

  context 'for an unknown task' do
    let(:definition) { nil }
    let(:annotation) do
      {
        "task" => "something",
        "value" => {"foo" => "bar"}
      }
    end

    it 'formats annotations for unknown tasks' do
      expect(formatted[:task]).to eq(annotation["task"])
      expect(formatted[:task_label]).to eq(nil)
      expect(formatted[:value]).to eq(annotation.to_json)
    end
  end
end
