FactoryGirl.define do
  factory :user_project_preference do
    user
    project
    email_communication true
    preferences '{"tutorial": "done"}'
    activity_count 19
  end
end
