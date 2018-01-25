# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :project_content do
    project
    language "en"
    title "A Test Project"
    description "Some Lorem Ipsum"
    introduction "MORE IPSUM"
    workflow_description "Go outside"
    researcher_quote "This is my favorite project"
    url_labels({"0.label" => "Blog", "1.label" => "Twitter", "2.label" => "Science Case"})
  end
end
