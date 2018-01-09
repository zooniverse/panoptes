FactoryGirl.define do
  factory :workflow_content do
    workflow
    language "en"
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

    trait :complex_task do
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

    trait :survey_task do
      strings({
        "T1.help"=>"this is a survey",
      })
    end

    trait :combo_task do
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
  end
end
