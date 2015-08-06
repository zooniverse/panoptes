FactoryGirl.define do
  factory :user_project_preference do
    transient do
      public false
    end

    user { create(:user, private_profile: !public) }
    project
    email_communication true
    preferences '{"tutorial": "done"}'
    activity_count 19
  end
end
