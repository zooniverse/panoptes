# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project_content do
    project
    language "en"
    title "A Test Project"
    description "Some Lorem Ipsum"
    introduction "MORE IPSUM"
    science_case "asdfasdf asdfasdf"
    team_members []
    guide({ "example_1" => "A descripton of it" })
  end
end
