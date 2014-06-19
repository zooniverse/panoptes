FactoryGirl.define do
  factory :project do
    sequence(:name) {|n| "test_project_#{n}"}
    display_name "Test Project"
    user_count { 10 + rand(1000) }
    activated_state :active
    visibility "public"
    primary_language "en"

    association :owner, factory: :user, password: "password"

    factory :project_with_workflows do
      after(:create) do |p|
        create_list(:workflow, 2, project: p)
      end
    end

    factory :project_with_subject_sets do
      after(:create) do |p|
        create_list(:subject_set, 2, project: p)
      end
    end

    factory :project_with_subjects do
      after(:create) do |p|
        create_list(:subject_set_with_subjects, 2, project: p)
      end
    end

    factory :project_with_contents do
      after(:create) do |p|
        create_list(:project_content, 1, project: p)
      end
    end
  end
end
