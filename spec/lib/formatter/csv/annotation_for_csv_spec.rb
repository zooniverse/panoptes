require 'spec_helper'

RSpec.describe Formatter::Csv::AnnotationForCsv do
  let(:workflow) { build_stubbed(:workflow, build_contents: false) }
  let(:contents) { build_stubbed(:workflow_content, workflow: workflow) }

  let(:classification) do
    build_stubbed(:classification, build_real_subjects: false).tap do |c|
      allow(c.workflow).to receive(:primary_content).and_return(contents)
    end
  end

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

  it 'adds the tool labels for drawing tasks', :aggregate_failures do
    formatted = described_class.new(classification, annotation).to_h
    expect(formatted["value"][0]["tool_label"]).to eq("Green")
    expect(formatted["value"][1]["tool_label"]).to eq("Blue")
    expect(formatted["value"][2]["tool_label"]).to eq("Green")
  end

  it 'has a nil label when the tool is not found in the workflow' do
    annotation = {"task" => "interest", "value" => [{"x"=>1, "y"=>2, "tool"=>1000}]}
    formatted = described_class.new(classification, annotation).to_h
    expect(formatted["value"][0]["tool_label"]).to be_nil
  end

  it 'returns an empty list of values when annotation itself has no value' do
    annotation = {"task" => "interest"}
    formatted = described_class.new(classification, annotation).to_h
    expect(formatted["value"]).to be_empty
  end

  context "when the the classification refers to the workflow and contents at a prev version" do
    with_versioning do
      let(:workflow) { create(:workflow) }
      let(:classification) do
        vers = "#{workflow.versions.first.index + 1}.#{workflow.workflow_contents.first.versions.first.index + 1}"
        create(:classification, build_real_subjects: false, workflow: workflow, workflow_version: vers)
      end

      before(:each) do
        workflow.update(tasks: { "init" =>
          { "T1" =>
              { "help" => "T1.help",
                "type" => "single",
                "answers" => [{ "label" => "T1.answers.0.label" }],
                "question" => "T1.question"
              }
          }
        })
        workflow.workflow_contents.first.update(strings: {
          "T1.question"=>"Is this a cat?",
          "T1.help"=>"",
          "T1.answers.0.label"=>"Enter an answer"
        })
      end

      it 'should add the correct version task label' do
        formatted = described_class.new(classification, annotation).to_h
        expect(formatted["task_label"]).to eq("Draw a circle")
      end
    end
  end
end
