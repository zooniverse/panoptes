FactoryGirl.define do
  factory :project do
    sequence(:name) {|n| "test_project_#{n}"}
    display_name "Test Project"
    user_count { 10 + rand(1000) }
    classification_count { 100 + rand(10000) }

    association :owner, factory: :user, password: "password"
  end
end
