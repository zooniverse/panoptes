require 'spec_helper'

RSpec.describe Warehouse::SingleTaskFormatter do
  let(:definition) do
    {
      "help" => "T2.help",
      "next" => "T3",
      "type" => "single",
      "question" => "T2.question",
      "answers" => [
        {"next" => "T3", "label" => "T2.answers.0.label"},
        {"next" => "T86", "label" => "T2.answers.1.label"},
        {"next" => "T67", "label" => "T2.answers.2.label"},
        {"next" => "T89", "label" => "T2.answers.3.label"},
        {"next" => "T71", "label" => "T2.answers.4.label"}
      ]
    }
  end

  let(:translations) do
    {
      "T2.question" => "Choose",
      "T2.answers.0.label" => "Number zero",
      "T2.answers.1.label" => "Number one"
    }
  end

  let(:formatted) do
    described_class.new(task_definition: definition, translations: translations).format(annotation)
  end

  context 'for a known task' do
    let(:annotation) do
      {"task" => "T2", "value" => 1}
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[:task]).to eq(annotation["task"])
      expect(formatted[:task_label]).to eq("Choose")
      expect(formatted[:task_type]).to eq("single")
      expect(formatted[:value]).to eq(1)
      expect(formatted[:value_label]).to eq("Number one")
    end
  end
end
