FactoryGirl.define do
  factory :project do
    sequence(:name) {|n| "test_project_#{n}"}
    display_name "Test Project"
    user_count { 10 + rand(1000) }
    classification_count { 100 + rand(10000) }

    association :owner, factory: :user, password: "password"

    factory :project_with_workflows do
      after(:create) do |p|
        n = Array(2..10).sample
        create_list(:workflow, n, project: p)
      end
    end

    factory :project_with_subject_groups do
      after(:create) do |p|
        n = Array(2..10).sample
        create_list(:subject_group, n, project: p)
      end
    end
  end
end
