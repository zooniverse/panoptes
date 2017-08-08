FactoryGirl.define do
  factory :translation do
    strings({
      title: "A test Project",
      description: "Some Lorem Ipsum",
      introduction: "Good times intro",
      workflow_description: "Go outside",
      researcher_quote: "This is my favorite project",
      url_labels: {"0.label" => "Blog", "1.label" => "Twitter", "2.label" => "Science Case"}
    })
    association :translated, factory: :project
    language "en-GB"
  end
end
