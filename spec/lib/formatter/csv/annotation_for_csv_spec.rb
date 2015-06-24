require 'spec_helper'

RSpec.describe Formatter::Csv::AnnotationForCsv do
  let(:classification) { create(:classification) }

  let(:annotation) do
    {
      "task" => "interest",
      "value" => [{"x"=>1, "y"=>2, "tool"=>1},
                  {"x"=>3, "y"=>4, "tool"=>2},
                  {"x"=>5, "y"=>6, "tool"=>1}]
    }
  end

  it 'adds the task label' do
    formatted = described_class.new(classification, annotation).to_h
    expect(formatted["task_label"]).to eq("Draw a circle")
  end

  it 'adds the tool labels for drawing tasks' do
    formatted = described_class.new(classification, annotation).to_h
    expect(formatted["value"][0]["tool_label"]).to eq("Green")
    expect(formatted["value"][1]["tool_label"]).to eq("Blue")
    expect(formatted["value"][2]["tool_label"]).to eq("Green")
  end
end
