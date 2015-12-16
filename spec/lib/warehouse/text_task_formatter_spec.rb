require 'spec_helper'

RSpec.describe Warehouse::TextTaskFormatter do
  let(:definition) do
    {"help"=>"T134.help", "type"=>"text", "instruction"=>"T134.instruction"}
  end

  let(:translations) do
    {"T134.instruction"=>"Record the name", "T134.help"=>""}
  end

  let(:formatted) do
    described_class.new(task_definition: definition, translations: translations).format(annotation)
  end

  context 'for a simple value' do
    let(:annotation) do
      {"task"=>"T134", "value"=>"testing this field."}
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[:task]).to eq(annotation["task"])
      expect(formatted[:task_label]).to eq("Record the name")
      expect(formatted[:task_type]).to eq("text")
      expect(formatted[:value]).to eq("testing this field.")
    end
  end
end
