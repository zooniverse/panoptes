require 'spec_helper'

RSpec.describe Warehouse::MultipleTaskFormatter do
  let(:definition) do
    {
      "help"=>"",
      "next"=>"T5",
      "type"=>"multiple",
      "answers"=>[{"label"=>"T3.answers.0.label"}, {"label"=>"T3.answers.1.label"}, {"label"=>"T3.answers.2.label"}],
      "question"=>"T3.question"
    }
  end

  let(:translations) do
    {
      "T3.question" => "Choose a colour",
      "T3.answers.0.label" => "Red",
      "T3.answers.1.label" => "Green",
      "T3.answers.2.label" => "Blue"
    }
  end

  let(:formatted) do
    described_class.new(task_definition: definition, translations: translations).format(annotation)
  end

  context 'for a single selected value' do
    let(:annotation) do
      {"task" => "T2", "value" => [1]}
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[0][:task]).to eq(annotation["task"])
      expect(formatted[0][:task_label]).to eq("Choose a colour")
      expect(formatted[0][:task_type]).to eq("multiple")
      expect(formatted[0][:value]).to eq(1)
      expect(formatted[0][:value_label]).to eq("Green")
    end
  end

  context 'for multiple selected values' do
    let(:annotation) do
      {"task" => "T2", "value" => [0,2]}
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[0][:task]).to eq(annotation["task"])
      expect(formatted[0][:task_label]).to eq("Choose a colour")
      expect(formatted[0][:task_type]).to eq("multiple")
      expect(formatted[0][:value]).to eq(0)
      expect(formatted[0][:value_label]).to eq("Red")

      expect(formatted[1][:task]).to eq(annotation["task"])
      expect(formatted[1][:task_label]).to eq("Choose a colour")
      expect(formatted[1][:task_type]).to eq("multiple")
      expect(formatted[1][:value]).to eq(2)
      expect(formatted[1][:value_label]).to eq("Blue")
    end
  end
end
