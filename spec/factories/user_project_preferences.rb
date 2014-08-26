FactoryGirl.define do
  factory :user_project_preference do
    user
    project
    email_communication true
    roles []
    preferences '{"tutorial": "done"}'
  end
end
