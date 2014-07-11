# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :uri_name do

    factory :uri_name_for_user do
      after(:build) do |user_uri_name|
        user = build(:user, password: "password", uri_name: user_uri_name)
        user_uri_name.resource = user
        unless user_uri_name.name
          user_uri_name.name = user.login
        end
      end
    end

    factory :uri_name_for_group do
      after(:build) do |user_group_uri_name|
        group = build(:user_group, uri_name: user_group_uri_name)
        user_group_uri_name.resource = group
        unless user_group_uri_name.name
          user_group_uri_name.name = group.display_name
        end
      end
    end
  end
end
