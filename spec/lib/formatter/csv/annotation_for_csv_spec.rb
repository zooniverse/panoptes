require 'spec_helper'

RSpec.describe Formatter::Csv::AnnotationForCsv do
  let(:workflow_version) { build_stubbed(:workflow_version, workflow: workflow, tasks: workflow.tasks, strings: workflow.strings) }
  let(:workflow) { build_stubbed(:workflow, build_contents: false) }
  let(:cache)    { instance_double("ClassificationDumpCache")}
  let(:classification) { build_stubbed(:classification, workflow: workflow, subjects: []) }
  let(:annotation) do
    {
      "task" => "interest",
      "value" => [{"x"=>1, "y"=>2, "tool"=>1},
                  {"x"=>3, "y"=>4, "tool"=>2},
                  {"x"=>5, "y"=>6, "tool"=>1}]
    }
  end
  let(:weird_annotation) do
    {
      "task" => "interest",
      "value" => [{"x"=>1, "y"=>2}]
    }
  end

  before do
    maj, min = classification.workflow_version.split('.').map(&:to_i)
    allow(cache).to receive(:workflow_at_version).with(workflow, maj, min).and_return(workflow_version)
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

  it 'adds an unknown tool label if the tool index is missing' do
    formatted = described_class.new(classification, weird_annotation, cache).to_h
    expect(formatted["value"][0]["tool_label"]).to be_nil
  end

  it 'returns the raw value if it is in an unexpected format' do
    weird_annotation["value"] = 0
    formatted = described_class.new(classification, weird_annotation, cache).to_h
    expect(formatted["value"]).to eq(Array.wrap(weird_annotation["value"]))
  end

  it 'has a nil label when the tool is not found in the workflow' do
    annotation = {"task" => "interest", "value" => [{"x"=>1, "y"=>2, "tool"=>1000}]}
    formatted = described_class.new(classification, annotation, cache).to_h
    expect(formatted["value"][0]["tool_label"]).to be_nil
  end

  it 'just records the tool index if the tool label cannot be translated' do
    annotation = {"task" => "interest", "value" => [{"x"=>1, "y"=>2, "tool"=>0}]}
    workflow_version.strings = {}
    formatter = described_class.new(classification, annotation, cache)
    formatted = formatter.to_h
    expect(formatted["value"][0]["tool_label"]).to be_nil
    expect(formatted["value"][0]["tool"]).to eq(0)
  end

  it 'returns an empty list of values when annotation itself has no value' do
    annotation = {"task" => "interest"}
    formatted = described_class.new(classification, annotation, cache).to_h
    expect(formatted["value"]).to be_empty
  end

  context "with a versioned workflow question type task" do
    with_versioning do
      let(:workflow) { build_stubbed(:workflow, :question_task) }

      let(:classification) do
        build_stubbed(:classification, subjects: [], workflow: workflow)
      end

      context "invalid annotation values" do
        it 'records an invalid answer label lookup for invalid indexes' do
          annotation = {"task" => "init", "value" => "YES" }
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["value"]).to eq("unknown answer label")
        end

        it 'records an invalid answer lookup for valid indexes' do
          annotation = {"task" => "init", "value" => 2 }
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["value"]).to eq("unknown answer label")
        end
      end

      context "with a single question workflow annotation" do
        it 'should add the correct answer label' do
          annotation = {"task" => "init", "value" => 1 }
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
          workflow_version.tasks = tasks
          workflow_version.strings = strings
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["value"]).to eq(["I sort of love it", "I don't love it"])
        end
      end

      context "with a combo task" do
        let(:classification) do
          build_stubbed(:classification, subjects: [], workflow: workflow, annotations: annotations)
        end
        let(:combo_annotation) { classification.annotations.first }

        context "with a valid annotation" do
          let(:workflow) { build_stubbed(:workflow, :complex_task) }
          let(:annotations) do
            [{
              "task"=>"T3",
              "value"=>[
                {"task"=>"init", "value"=>1},
                {"task"=>"T2", "value"=>[1]},
                {"task"=>"T6", "value"=>"no secrets between us, panoptes. you see all."},
                {"task"=>"T7", "value"=>[
                  {"value"=>"c6e0d98477ec8", "option"=>true},
                  {"value"=>"fb39ba165bfd4", "option"=>true},
                  {"value"=>"81a10debaa648", "option"=>true}
                ]}
              ]
            }]
          end
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
                  "value"=>["Tomato?!"]
                },
                {
                  "task"=>"T6",
                  "value"=>"no secrets between us, panoptes. you see all.",
                  "task_label"=>"Tell me a secret."
                },
                {
                  "task"=>"T7",
                  "value"=> [
                    {"select_label"=>"Country", "option"=>true, "value"=>"c6e0d98477ec8", "label"=>"Oceania"},
                    {"select_label"=>"State", "option"=>true, "value"=>"fb39ba165bfd4", "label"=>"Left Oceania"},
                    {"select_label"=>"City", "option"=>true, "value"=>"81a10debaa648", "label"=>"Townsville"}
                  ]
                }
              ]
            }
          end

          it 'should add the correct answer labels' do
            formatted = described_class.new(classification, combo_annotation, cache).to_h
            expect(formatted).to eq(codex)
          end
        end

        context "with an malformed annotation" do
          let(:workflow) { build_stubbed(:workflow, :combo_task) }
          let(:annotations) do
            # A valid annotation for the combo task
            # [{ "task"=>"T3", "value"=>[
            #   {"task"=>"T1", "value"=>"Reginald P. Herring the third"},
            #   {"task"=>"T2", "value"=>[2]}
            # ]}]
            # An example annotation from tropical sweden project
            [
              { "task"=>"T3", "value"=>0 },
              {"task"=>"T1", "value"=>"Reginald P. Herring the third"},
              {"task"=>"T2", "value"=>[2]}
            ]
          end
          let(:codex) do
            { "task"=>"T3", "task_label"=>nil, "value"=>[0] }
          end

          it 'should output the raw value wrapped in an array' do
            formatted = described_class.new(classification, combo_annotation, cache).to_h
            expect(formatted).to eq(codex)
          end
        end
      end

      context "with a dropdown task" do
        let(:workflow) { build_stubbed(:workflow, :complex_task) }
        let(:annotation) do
          {
            "task"=>"T7",
            "value"=>[
              {"value"=>"c6e0d98477ec8", "option"=>true},
              {"value"=>"fb39ba165bfd4", "option"=>true},
              {"value"=>"something unlisted", "option"=>false}
            ]
           }
        end

        let(:classification) do
          build_stubbed(:classification, subjects: [], workflow: workflow, annotations: [annotation])
        end

        let(:codex) do
          {
            "task"=>"T7",
            "value"=> [
              {"select_label"=>"Country", "option"=>true, "value"=>"c6e0d98477ec8", "label"=>"Oceania"},
              {"select_label"=>"State", "option"=>true, "value"=>"fb39ba165bfd4", "label"=>"Left Oceania"},
              {"select_label"=>"City", "option"=>false, "value"=>"something unlisted"}
            ]
          }
        end

        it 'should add the correct answer labels' do
          formatted = described_class.new(classification, classification.annotations[0], cache).to_h
          expect(formatted).to eq(codex)
        end

        context "with a empty array value (found in production db)" do
          let(:annotation) do
            {"task"=>"T7", "value"=>[]}
          end

          let(:codex) do
            {
              "task"=>"T7",
              "value"=> [
                {"select_label"=>"Country"},
                {"select_label"=>"State", "option"=>false, "value"=>nil},
                {"select_label"=>"City", "option"=>false, "value"=>nil}
              ]
            }
          end

          it 'should add the correct answer labels' do
            formatted = described_class.new(classification, classification.annotations[0], cache).to_h
            expect(formatted).to eq(codex)
          end
        end
      end

      context "with a survey task" do
        let(:annotation) do
           {"task"=>"T1", "value"=>[{"choice"=>"DR", "answers"=>{"BHVR"=>["MVNG"], "DLTNTLRLSS"=>"1"}, "filters"=>{}}]}
        end
        let(:workflow) { build_stubbed(:workflow, :survey_task) }
        let(:classification) do
          build_stubbed(:classification, subjects: [], workflow: workflow, annotations: [annotation])
        end

        it 'returns the unaltered annotation' do
          formatted = described_class.new(classification, classification.annotations[0], cache).to_h
          expect(formatted).to eq(annotation)
        end
      end

      context "when the classification refers to the workflow and contents at a prev version" do
        let(:workflow_version) { build_stubbed(:workflow_version, workflow: workflow, strings: {'interest.question' => 'Old version'}) }
        let(:classification) do
          vers = "8888888.999999"
          build_stubbed(:classification, subjects: [], workflow: workflow, workflow_version: vers)
        end

        it 'should add the correct version task label' do
          allow(cache).to receive(:workflow_at_version).with(workflow, 1, 1).and_return(workflow_version)
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["task_label"]).to eq("Old version")
        end
      end

      context "with a shortcut task" do
        let(:workflow) { build_stubbed(:workflow, :shortcut) }
        let(:tasks) { workflow.tasks }
        let(:strings) { contents.strings }
        let(:annotation) do
          {
            "task"=>"init",
            "value"=> 0
           }
        end

        it 'should add the correct answer labels' do
          formatted = described_class.new(classification, annotation, cache).to_h
          expect(formatted["task_label"]).to eq("Fire present?")
          expect(formatted["value"]).to eq(["yes"])
        end
      end
    end
  end
end
