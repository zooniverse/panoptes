require 'spec_helper'

RSpec.describe Formatter::Csv::AnnotationForCsv do
  let(:contents) { build_stubbed(:workflow_content, workflow: nil) }
  let(:workflow) { build_stubbed(:workflow, workflow_contents: [contents], build_contents: false) }
  let(:cache)    { double(workflow_at_version: workflow, workflow_content_at_version: contents)}

  let(:classification) do
    build_stubbed(:classification, subjects: []).tap do |c|
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
    formatted = described_class.new(classification, annotation, cache).to_h
    expect(formatted["task_label"]).to eq("Draw a circle")
  end

  it 'adds the tool labels for drawing tasks', :aggregate_failures do
    formatted = described_class.new(classification, annotation, cache).to_h
    expect(formatted["value"][0]["tool_label"]).to eq("Green")
    expect(formatted["value"][1]["tool_label"]).to eq("Blue")
    expect(formatted["value"][2]["tool_label"]).to eq("Green")
  end

  it 'has a nil label when the tool is not found in the workflow' do
    annotation = {"task" => "interest", "value" => [{"x"=>1, "y"=>2, "tool"=>1000}]}
    formatted = described_class.new(classification, annotation, cache).to_h
    expect(formatted["value"][0]["tool_label"]).to be_nil
  end

  it 'returns an empty list of values when annotation itself has no value' do
    annotation = {"task" => "interest"}
    formatted = described_class.new(classification, annotation, cache).to_h
    expect(formatted["value"]).to be_empty
  end

  context "with a versioned workflow question type task" do
    with_versioning do
      let(:workflow) { create(:workflow, workflow_contents: []) }
      let(:contents) { create(:workflow_content, workflow: workflow) }
      let(:classification) do
        build_stubbed(:classification, subjects: [], workflow: workflow)
      end
      let(:q_workflow) { build(:workflow, :question_task) }
      let(:tasks) { q_workflow.tasks }
      let(:strings) { q_workflow.workflow_contents.first.strings }

      before(:each) do
        workflow.update(workflow_contents: [contents], tasks: tasks)
        contents.update(strings: strings)
      end

      context "with a single question workflow annotation" do
        let(:annotation) { { task: "init", value: 1 } }

        it 'should add the correct answer label' do
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["value"]).to eq("No")
        end
      end

      context "with a multiple question workflow annotation" do
        let(:tasks) do
          {
            "T1" => {
              "help" => "T1.help",
              "type" => "multiple",
              "answers" => [{ "label" => "T1.answers.0.label" },
                            { "label" => "T1.answers.1.label" },
                            { "label" => "T1.answers.2.label" }],
              "question" => "T1.question"
            }
          }
        end
        let(:strings) do
          {
            "T1.question"=>"How much do you love it?",
            "T1.help"=>"It's not too hard...",
            "T1.answers.0.label"=>"I sort of love it",
            "T1.answers.1.label"=>"I want to take it home",
            "T1.answers.2.label"=>"I don't love it"
          }
        end
        let(:annotation) { { task: "T1", value: [0,2] } }

        it 'should add the correct answer labels' do
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["value"]).to eq(["I sort of love it", "I don't love it"])
        end
      end

      context "with a combo task" do
        let(:combo_workflow) { build(:workflow, :combo_task) }
        let(:annotation) do
          {
            "task"=>"T3",
            "value"=>[
              {"task"=>"init", "value"=>1},
              {"task"=>"T2", "value"=>[1]},
              {"task"=>"T6", "value"=>"no secrets between us, panoptes. you see all."}
            ]
          }
        end

        let(:new_classification) do
          build_stubbed(:classification, subjects: [], workflow: combo_workflow, annotations: [annotation])
        end
        let(:combo_contents) { create(:workflow_content, :combo_task, workflow: combo_workflow) }
        let(:combo_cache) { double(workflow_at_version: combo_workflow, workflow_content_at_version: combo_contents)}

        let(:codex) do
          {
            "task"=>"T3",
            "task_label"=>nil,
            "value"=>[
              {
                "task"=>"init",
                "task_label"=>"Are you sure? (SINGLE)",
                "value"=>"Well now I'm second guessing myself"
              },
              {
                "task"=>"T2",
                "task_label"=>"FRUITS?!?! (MULTIPLE)",
                "value"=>"Tomato?!"
              },
              {
                "task"=>"T6",
                "value"=>"no secrets between us, panoptes. you see all.",
                "task_label"=>"Tell me a secret."
              }
            ]
          }
        end

        it 'should add the correct answer labels' do
          formatted = described_class.new(new_classification, new_classification.annotations[0], combo_cache).to_h
          expect(formatted).to eq(codex)
        end

      end

      context "with a dropdown task" do
        let(:dd_workflow) { build(:workflow, :dropdown_task) }
        let(:annotation) do
          {
            "task"=>"T7",
            "value"=>[
              {"value"=>"c6e0d98477ec8", "option"=>true},
              {"value"=>"fb39ba165bfd4", "option"=>true},
              {"value"=>"81a10debaa648", "option"=>true}
            ]
           }
        end

        let(:dd_classification) do
          build_stubbed(:classification, subjects: [], workflow: dd_workflow, annotations: [annotation])
        end
        let(:dd_contents) { create(:workflow_content, :dropdown_task, workflow: dd_workflow) }
        let(:dd_cache) { double(workflow_at_version: dd_workflow, workflow_content_at_version: dd_contents)}

        let(:codex) do
          {
            "task"=>"T7",
            "value"=> [
              {"select_label"=>"Country", "option"=>false, "value"=>"c6e0d98477ec8", "label"=>"Oceania"},
              {"select_label"=>"State", "option"=>true, "value"=>"fb39ba165bfd4", "label"=>"Left Oceania"},
              {"select_label"=>"City", "option"=>true, "value"=>"81a10debaa648", "label"=>"Townsville"}
            ]
          }
        end

        it 'should add the correct answer labels' do
          formatted = described_class.new(dd_classification, dd_classification.annotations[0], dd_cache).to_h
          expect(formatted).to eq(codex)
        end

      end

      context "when the classification refers to the workflow and contents at a prev version" do
        let(:classification) do
          vers = "#{workflow.versions.first.index + 1}.#{contents.versions.first.index + 1}"
          build_stubbed(:classification, subjects: [], workflow: workflow, workflow_version: vers)
        end

        it 'should add the correct version task label' do
          allow(cache).to receive(:workflow_at_version).with(workflow.id, 1).and_return(workflow.versions[1].reify)
          allow(cache).to receive(:workflow_content_at_version).with(contents.id, 1).and_return(contents.versions[1].reify)
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["task_label"]).to eq("Draw a circle")
        end
      end
    end
  end
end
