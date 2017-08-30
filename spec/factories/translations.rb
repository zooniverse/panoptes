FactoryGirl.define do
  factory :translation, aliases: [:project_translation] do
    strings({
      title: "A test Project",
      description: "Some Lorem Ipsum",
      introduction: "Good times intro",
      workflow_description: "Go outside",
      researcher_quote: "This is my favorite project",
      urls: [
        {label: "Blog", url: "http://blog.example.com/"},
        {label: "Twitter", url: "http://twitter.com/example"}
      ]
    })
    association :translated, factory: :project
    language "en-GB"

    factory :workflow_translation do
      strings({
        display_name: "A translated Workflow name",
        tasks: [
          interest: {
            type: 'drawing',
            question: "Draw a circle",
            help: "Duh?",
            # the tool lables array might be best un-wound to avoid ambiguity
            # "tool_lablel.2" => "Blue",
            tool_labels: %w(Red Green Blue)
          },
          shape: {
            question: "What shape is this galaxy",
            help: "Duh?",
            # the answers array might be best un-wound to avoid ambiguity
            # "answers.0" => "Smooth",
            answers: ["Smooth", "Features", "Star or artifact"]
          }
        ]
      })

      association :translated, factory: :workflow
    end
  end
end
