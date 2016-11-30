# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :access_control_list do
    association :user_group, factory: :user_group_with_users
    roles ["collaborator"]
    association :resource, factory: :project
  end
end
