# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :uri_name do
    sequence(:name) {|n| "MyString_#{n}"}

    factory :uri_name_for_user do
      after(:build) do |user_uri_name|
        user = build(:user, password: "password", uri_name: user_uri_name)
        user_uri_name.resource = user
      end
    end

    factory :uri_name_for_group do
      after(:build) do |user_group_uri_name|
        group = build(:user_group, uri_name: user_group_uri_name)
        user_group_uri_name.resource = group
      end
    end
  end
end
