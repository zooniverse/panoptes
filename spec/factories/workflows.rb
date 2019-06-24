FactoryBot.define do
  factory :workflow, aliases: [:workflow_with_contents] do
    display_name "A Workflow"

    first_task "interest"
    tasks(
      {
        interest: {
          type: 'drawing',
          question: "interest.question",
          help: "interest.help",
          tools: [
            {value: 'red', label: "interest.tools.0.label", type: 'point', color: 'red'},
            {value: 'green', label: "interest.tools.1.label", type: 'point', color: 'lime'},
            {value: 'blue', label: "interest.tools.2.label", type: 'point', color: 'blue'},
            {
              label: "interest.tools.3.label",
              type: 'ellipse',
              color: 'purple',
              details: [{
                type: "single",
                answers: [
                  { label: "interest.tools.3.details.0.answers.0.label"},
                  { label: "interest.tools.3.details.0.answers.1.label"}
                ],
                question: "interest.tools.3.details.0.question"
              }]
            }
          ],
          next: 'shape'
        },
        shape: {
          type: 'multiple',
          question: "shape.question",
          help: "shape.help",
          answers: [
            {value: 'smooth', label: "shape.answers.0.label"},
            {value: 'features', label: "shape.answers.1.label"},
            {value: 'other', label: "shape.answers.2.label"}
          ],
          required: true,
          next: 'roundness'
        }
      }
    )

    steps([])

    pairwise false
    grouped false
    prioritized false
    primary_language 'en'
    project
    retired_set_member_subjects_count 0
    subject_selection_strategy "builtin"

    strings({
            "interest.question" => "Draw a circle",
            "interest.help" => "Duh?",
            "interest.tools.0.label" => "Red",
            "interest.tools.1.label" => "Green",
            "interest.tools.2.label" => "Blue",
            "interest.tools.3.label" => "Purple",
            "interest.tools.3.details.0.answers.0.label"=>"Painfully wow",
            "interest.tools.3.details.0.answers.1.label"=>"Just wow",
            "interest.tools.3.details.0.question"=>"Wow rating:",
            "shape.question" => "What shape is this galaxy",
            "shape.help" => "Duh?",
            "shape.answers.0.label" => "Smooth",
            "shape.answers.1.label" => "Features",
            "shape.answers.2.label" => "Star or artifact",
            })

    factory :workflow_with_subject_set do
      after(:create) do |w|
        create_list(:subject_set, 1, workflows: [w], project: w.project)
      end
    end

    factory :workflow_with_subject_sets do
      after(:create) do |w|
        create_list(:subject_set, 2, workflows: [w], project: w.project)
      end
    end

    factory :workflow_with_subjects do
      ignore do
        num_sets 2
      end

      after(:create) do |w, evaluator|
        create_list(:subject_set_with_subjects, evaluator.num_sets, workflows: [w], project: w.project)
        w.real_set_member_subjects_count = w.non_training_subject_sets.sum(:set_member_subjects_count)
      end
    end

    trait :designator do
      subject_selection_strategy "designator"
    end

    trait :question_task do
      tasks (
        {
          "init" => {
            "help" => "init.help",
            "type" => "single",
            "answers" => [{ "label" => "init.answers.0.label" },
                          { "label" => "init.answers.1.label" }],
            "question" => "init.question",
            "required" => true
          }
        }
      )

      strings ({
        "init.help" => "You know what a cat looks like right?",
        "init.answers.0.label" => "Yes",
        "init.answers.1.label" => "No",
        "init.question" => "Is there a cat in the image"
      })
    end

    trait :survey_task do
      display_name "Survey Workflow"
      tasks ({
        "T1"=>{
          "type"=>"survey"
        }
      })
      strings({
        "T1.help"=>"this is a survey",
      })
    end

    trait :complex_task do
      display_name "Complex Workflow"
      tasks (
        {
          "T2"=>{
          "help"=>"T2.help",
          "type"=>"multiple",
          "answers"=>[
            {"label"=>"T2.answers.0.label"},
            {"label"=>"T2.answers.1.label"},
            {"label"=>"T2.answers.2.label"}
          ],
          "question"=>"T2.question"
        },
          "T3"=>{
            "type"=>"combo",
            "tasks"=>["init", "T2", "T6"]
        },
          "T6"=>{
            "help"=>"T6.help",
            "type"=>"text",
            "instruction"=>"T6.instruction"
        },
          "init"=> {
            "type"=>"single",
            "answers"=>[
              {"next"=>"T2", "label"=>"init.answers.0.label"},
              {"label"=>"init.answers.1.label"}
            ],
            "question"=>"init.question"
        },
          "T7"=>{
            "help"=>"T7.help",
            "type"=>"dropdown",
            "selects"=>
              [{"id"=>"c99e5ef444475",
                "title"=>"Country",
                "options"=>
                 {"*"=>
                   [{"label"=>"T7.selects.0.options.*.0.label",
                     "value"=>"c6e0d98477ec8"},
                    {"label"=>"T7.selects.0.options.*.1.label",
                     "value"=>"3a9b7c7d53d6f"},
                    {"label"=>"T7.selects.0.options.*.2.label",
                     "value"=>"3844fc24a3df7"}]},
                "required"=>true,
                "allowCreate"=>false},
               {"id"=>"e7e963e06159e",
                "title"=>"State",
                "options"=>
                 {"3844fc24a3df7"=>
                   [{"label"=>"T7.selects.1.options.3844fc24a3df7.0.label",
                     "value"=>"2619efdf9012"},
                    {"label"=>"T7.selects.1.options.3844fc24a3df7.1.label",
                     "value"=>"2f003e4bac96b"}],
                  "3a9b7c7d53d6f"=>
                   [{"label"=>"T7.selects.1.options.3a9b7c7d53d6f.0.label",
                     "value"=>"5243f2462e8b7"},
                    {"label"=>"T7.selects.1.options.3a9b7c7d53d6f.1.label",
                     "value"=>"ddb28c5f936ac"}],
                  "c6e0d98477ec8"=>
                   [{"label"=>"T7.selects.1.options.c6e0d98477ec8.0.label",
                     "value"=>"fb39ba165bfd4"},
                    {"label"=>"T7.selects.1.options.c6e0d98477ec8.1.label",
                     "value"=>"74ad7005baad5"}]},
                "required"=>false,
                "condition"=>"c99e5ef444475",
                "allowCreate"=>true},
               {"id"=>"2f54a93bb2804",
                "title"=>"City",
                "options"=>
                 {"3844fc24a3df7;2619efdf9012"=>
                   [{"label"=>"T7.selects.2.options.3844fc24a3df7;2619efdf9012.0.label",
                     "value"=>"24f09ef4d999c"},
                    {"label"=>"T7.selects.2.options.3844fc24a3df7;2619efdf9012.1.label",
                     "value"=>"515e2031a9f2"}],
                  "3844fc24a3df7;2f003e4bac96b"=>
                   [{"label"=>"T7.selects.2.options.3844fc24a3df7;2f003e4bac96b.0.label",
                     "value"=>"908c3c68e1f36"},
                    {"label"=>"T7.selects.2.options.3844fc24a3df7;2f003e4bac96b.1.label",
                     "value"=>"48b9769fe7556"}],
                  "3a9b7c7d53d6f;5243f2462e8b7"=>
                   [{"label"=>"T7.selects.2.options.3a9b7c7d53d6f;5243f2462e8b7.0.label",
                     "value"=>"be506b6d9e42e"},
                    {"label"=>"T7.selects.2.options.3a9b7c7d53d6f;5243f2462e8b7.1.label",
                     "value"=>"11a1c32d3a6ca"}],
                  "3a9b7c7d53d6f;ddb28c5f936ac"=>
                   [{"label"=>"T7.selects.2.options.3a9b7c7d53d6f;ddb28c5f936ac.0.label",
                     "value"=>"7c9fe6fb69c1d"},
                    {"label"=>"T7.selects.2.options.3a9b7c7d53d6f;ddb28c5f936ac.1.label",
                     "value"=>"d8fb8a1489c3c"}],
                  "c6e0d98477ec8;74ad7005baad5"=>
                   [{"label"=>"T7.selects.2.options.c6e0d98477ec8;74ad7005baad5.0.label",
                     "value"=>"3935249042d33"},
                    {"label"=>"T7.selects.2.options.c6e0d98477ec8;74ad7005baad5.1.label",
                     "value"=>"bf2ac1dff4aee"}],
                  "c6e0d98477ec8;fb39ba165bfd4"=>
                   [{"label"=>"T7.selects.2.options.c6e0d98477ec8;fb39ba165bfd4.0.label",
                     "value"=>"81a10debaa648"},
                    {"label"=>"T7.selects.2.options.c6e0d98477ec8;fb39ba165bfd4.1.label",
                     "value"=>"acef6073251e2"}]},
                "required"=>false,
                "condition"=>"e7e963e06159e",
                "allowCreate"=>true}],
             "instruction"=>"T7.instruction"
          }
        }
      )

      strings({
        "T2.help"=>"Just pick a fruit already",
        "T2.answers.0.label"=>"Pineapple",
        "T2.answers.1.label"=>"Tomato?!",
        "T2.answers.2.label"=>"An Old Peach",
        "T2.question"=>"FRUITS?!?! (MULTIPLE)",
        "init.answers.0.label"=>"I'm positive.",
        "init.answers.1.label"=>"Well now I'm second guessing myself",
        "init.question"=>"Are you sure? (SINGLE)",
        "T6.instruction"=>"Tell me a secret.",
        "T6.help"=>"A really good one, pls",
        "T7.help"=>"it drops down",
        "T7.selects.0.options.*.0.label"=>"Oceania",
        "T7.selects.0.options.*.1.label"=>"Eurasia",
        "T7.selects.0.options.*.2.label"=>"US",
        "T7.selects.1.options.3844fc24a3df7.0.label"=>"Arizona",
        "T7.selects.1.options.3844fc24a3df7.1.label"=>"Illinois",
        "T7.selects.1.options.c6e0d98477ec8.0.label"=>"Left Oceania",
        "T7.selects.1.options.c6e0d98477ec8.1.label"=>"Right Oceania",
        "T7.selects.1.options.3a9b7c7d53d6f.0.label"=>"Left Eurasia",
        "T7.selects.1.options.3a9b7c7d53d6f.1.label"=>"Right Eurasia",
        "T7.selects.2.options.c6e0d98477ec8;fb39ba165bfd4.0.label"=>"Townsville",
        "T7.selects.2.options.c6e0d98477ec8;fb39ba165bfd4.1.label"=>"Cityton",
        "T7.selects.2.options.c6e0d98477ec8;74ad7005baad5.0.label"=>"Green Acres",
        "T7.selects.2.options.c6e0d98477ec8;74ad7005baad5.1.label"=>"Palm Springs",
        "T7.selects.2.options.3a9b7c7d53d6f;5243f2462e8b7.0.label"=>"Best City",
        "T7.selects.2.options.3a9b7c7d53d6f;5243f2462e8b7.1.label"=>"Tryhard Junction",
        "T7.selects.2.options.3a9b7c7d53d6f;ddb28c5f936ac.0.label"=>"Independant New South Bummersville",
        "T7.selects.2.options.3a9b7c7d53d6f;ddb28c5f936ac.1.label"=>"Cowton",
        "T7.selects.2.options.3844fc24a3df7;2619efdf9012.0.label"=>"Phoenix",
        "T7.selects.2.options.3844fc24a3df7;2619efdf9012.1.label"=>"Tucson",
        "T7.selects.2.options.3844fc24a3df7;2f003e4bac96b.0.label"=>"Chicago",
        "T7.selects.2.options.3844fc24a3df7;2f003e4bac96b.1.label"=>"Everywhere Else",
        "T7.instruction"=>"DROPPIN' DOWN"
      })
    end

    trait :combo_task do
      display_name "Combo Task Workflow"
      first_task "T3"
      tasks ({
        "T1"=>{
          "help"=>"T1.help",
          "type"=>"text",
          "instruction"=>"T1.instruction"
        },
        "T2"=>{
          "help"=>"T2.help",
          "type"=>"multiple",
          "answers"=>[
            {"label"=>"T2.answers.0.label"},
            {"label"=>"T2.answers.1.label"},
            {"label"=>"T2.answers.2.label"}
          ],
          "question"=>"T2.question"
        },
        "T3"=>{
          "type"=>"combo",
          "tasks"=>["T1", "T2"]
        }
      })
      strings({
        "T1.help"=>"Just pick a fruit already",
        "T1.instruction"=>"Tell me a secret.",
        "T2.help"=>"Help is needed here I see",
        "T2.question"=>"Choose one of the labels",
        "T2.answers.0.label"=>"I'm positive.",
        "T2.answers.1.label"=>"Well now I'm second guessing myself",
        "T2.answers.2.label"=>"Has to be the correct one, for sure...right"
      })
    end

    trait :shortcut do
      tasks (
        {
          "init" => {
            "type" => "shortcut",
            "answers" => [{ "label" => "init.answers.0.label" }],
            "question" => "init.question"
          }
        }
      )
      strings ({
        "init.answers.0.label" => "yes",
        "init.question" => "Fire present?"
      })
    end
  end
end
