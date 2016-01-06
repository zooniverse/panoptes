require 'spec_helper'

RSpec.describe Warehouse::CropTaskFormatter do
  let(:definition) do
    {"help"=>"T4.help", "next"=>"T2", "type"=>"crop", "instruction"=>"T4.instruction"}
  end

  let(:translations) do
    {"T4.instruction"=>"Zoom in on eye", "T4.help"=>""}
  end

  let(:formatted) do
    described_class.new(task_definition: definition, translations: translations).format(annotation)
  end

  context 'for a simple value' do
    let(:annotation) do
     {"task"=>"T4", "value"=>{"x"=>211.3125, "y"=>134, "width"=>168, "height"=>143}}
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[:task]).to eq(annotation["task"])
      expect(formatted[:task_label]).to eq("Zoom in on eye")
      expect(formatted[:task_type]).to eq("crop")
      expect(formatted[:value]).to eq(annotation["value"].to_json)
    end
  end
end
