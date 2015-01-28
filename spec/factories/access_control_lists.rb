# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :access_control_list do
    user_group
    roles ["collaborator"]
    association :resource, factory: :project
  end
end
