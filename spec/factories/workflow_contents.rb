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
  end
end
