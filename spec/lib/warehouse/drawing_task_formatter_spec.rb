require 'spec_helper'

RSpec.describe Warehouse::DrawingTaskFormatter do
  let(:definition) do
    {"help"=>"T1.help",
      "next"=>"T3",
      "type"=>"drawing",
      "tools"=>
        [{"type"=>"point", "color"=>"#ff0000", "label"=>"T1.tools.0.label", "details"=>[]},
         {"type"=>"point", "color"=>"#00ffff", "label"=>"T1.tools.1.label", "details"=>[]},
         {"type"=>"point", "color"=>"#0000ff", "label"=>"T1.tools.2.label", "details"=>[]},
         {"type"=>"point", "color"=>"#ff00ff", "label"=>"T1.tools.3.label", "details"=>[]},
         {"type"=>"point", "color"=>"#000000", "label"=>"T1.tools.4.label", "details"=>[
           {"help"=>"T1.tools.4.details.0.help",
             "type"=>"single",
             "answers"=>
               [{"label"=>"T1.tools.4.details.0.answers.0.label"},
                {"label"=>"T1.tools.4.details.0.answers.1.label"},
                {"label"=>"T1.tools.4.details.0.answers.2.label"},
                {"label"=>"T1.tools.4.details.0.answers.3.label"}],
             "question"=>"T1.tools.4.details.0.question",
             "required"=>true}]},
         {"type"=>"point", "color"=>"#00ff00", "label"=>"T1.tools.5.label", "details"=>[
           {"help"=>"T1.tools.5.details.0.help",
             "type"=>"multiple",
             "answers"=>
               [{"label"=>"T1.tools.5.details.0.answers.0.label"},
                {"label"=>"T1.tools.5.details.0.answers.1.label"},
                {"label"=>"T1.tools.5.details.0.answers.2.label"},
                {"label"=>"T1.tools.5.details.0.answers.3.label"},
                {"label"=>"T1.tools.5.details.0.answers.4.label"},
                {"label"=>"T1.tools.5.details.0.answers.5.label"},
                {"label"=>"T1.tools.5.details.0.answers.6.label"}],
             "question"=>"T1.tools.5.details.0.question",
             "required"=>true}]}],
      "instruction"=>"T1.instruction"}
  end

  let(:translations) do
    {
      "T1.tools.0.label"=>"Basalt",
      "T1.tools.1.label"=>"Pummice",
      "T1.tools.2.label"=>"Quartz",
      "T1.tools.3.label"=>"Calcrete",
      "T1.tools.4.label"=>"Claystone",
      "T1.tools.4.details.0.help"=>"",
      "T1.tools.4.details.0.answers.0.label"=>"yellow",
      "T1.tools.4.details.0.answers.1.label"=>"olive",
      "T1.tools.4.details.0.answers.2.label"=>"grey",
      "T1.tools.4.details.0.answers.3.label"=>"white",
      "T1.tools.4.details.0.question"=>"What colour?",
      "T1.tools.5.label"=>"Sandstone",
      "T1.tools.5.details.0.help"=>"",
      "T1.tools.5.details.0.answers.0.label"=>"Fine",
      "T1.tools.5.details.0.answers.1.label"=>"Coarse",
      "T1.tools.5.details.0.answers.2.label"=>"Conglomerate",
      "T1.tools.5.details.0.answers.3.label"=>"Fossil Rich",
      "T1.tools.5.details.0.answers.4.label"=>"Bioturbated",
      "T1.tools.5.details.0.answers.5.label"=>"Laminated",
      "T1.tools.5.details.0.answers.6.label"=>"not sure",
      "T1.tools.5.details.0.question"=>"What Type?\n*you can select more than one*",
      "T1.instruction"=>"Do you see any of these rock, clast or mineral types?"
    }
  end

  let(:formatted) do
    described_class.new(task_definition: definition, translations: translations).format(annotation)
  end

  context 'for multiple points' do
    let(:annotation) do
      {"task"=>"T1",
        "value"=>
          [{"x"=>506.00060605882135, "y"=>670.0977900977902, "tool"=>5, "frame"=>0, "details"=>[{"value"=>[1]}]},
           {"x"=>277.71078251942726, "y"=>33.572033572033575, "tool"=>5, "frame"=>0, "details"=>[{"value"=>[6]}]},
           {"x"=>742.3477174878411, "y"=>189.34626934626934, "tool"=>4, "frame"=>0, "details"=>[{"value"=>3}]},
           {"x"=>242.79586833104935, "y"=>197.40355740355741, "tool"=>2, "frame"=>0, "details"=>[]}]}
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted.size).to eq(4)

      expect(formatted[0][:task]).to eq(annotation["task"])
      expect(formatted[0][:task_label]).to eq(translations["T1.instruction"])
      expect(formatted[0][:task_type]).to eq("drawing")
      expect(formatted[0][:tool]).to eq(5)
      expect(formatted[0][:tool_label]).to eq(translations["T1.tools.5.label"])
      expect(formatted[0][:marking]).to eq("506.0006,670.0978")
      expect(formatted[0][:frame]).to eq(0)
      expect(formatted[0][:details]).to eq(annotation["value"][0]["details"].to_json)
    end
  end
end
