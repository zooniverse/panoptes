# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :owner_name do

    factory :owner_name_for_user do
      after(:build) do |user_owner_name|
        user = build(:user, password: "password", owner_name: user_owner_name)
        user_owner_name.resource = user
        unless user_owner_name.name
          user_owner_name.name = user.login
        end
      end
    end

    factory :owner_name_for_group do
      after(:build) do |user_group_owner_name|
        group = build(:user_group, owner_name: user_group_owner_name)
        user_group_owner_name.resource = group
        unless user_group_owner_name.name
          user_group_owner_name.name = group.name
        end
      end
    end
  end
end
