FactoryBot.define do
  factory :translation, aliases: [:project_translation] do
    strings({
      title: "A test Project",
      description: "Some Lorem Ipsum",
      introduction: "Good times intro",
      workflow_description: "Go outside",
      researcher_quote: "This is my favorite project",
      "urls.0.label" => "Blog",
      "urls.1.label" => "Twitter"
    })
    association :translated, factory: :project
    language "en-GB"

    factory :workflow_translation do
      strings({
        "display_name" => "A translated Workflow name",
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

      association :translated, factory: :workflow
    end
  end
end
