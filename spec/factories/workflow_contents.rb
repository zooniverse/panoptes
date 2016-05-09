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
            "shape.question" => "What shape is this galaxy",
            "shape.help" => "Duh?",
            "shape.answers.0.label" => "Smooth",
            "shape.answers.1.label" => "Features",
            "shape.answers.2.label" => "Star or artifact",
            })

    factory :combo_workflow_content do
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
            "T6.help"=>"A really good one, pls"
            })
    end
  end
end
