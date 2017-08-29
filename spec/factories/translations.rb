FactoryGirl.define do
  factory :translation do
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
  end
end
