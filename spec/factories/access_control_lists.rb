# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :access_control_list do
    user_group
    roles { ["collaborator"] }
    association :resource, factory: :project

    factory :access_control_list_with_user_group do
      association :user_group, factory: :user_group_with_users
    end

  end
end
