FactoryGirl.define do
  factory :user_project_preference do
    user
    project
    email_communication true
    preferences '{"tutorial": "done"}'
    activity_count { { asteroid: { count: "19", updated_at: "2014-10-14 17:29:23 UTC" } } }
  end
end
