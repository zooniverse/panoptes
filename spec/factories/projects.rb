FactoryGirl.define do
  factory :project do
    sequence(:name) { |n| "test_project_#{ n }" }
    sequence(:display_name) { |n| "Test Project #{ n }" }
    user_count { 10 + rand(1000) }
    activated_state :active
    primary_language "en"
    avatar "http://test.host/x02234.jpg.gif.png.webp"
    background_image "http://test.host/12312asd.jp2"
    visible_to []

    association :owner, factory: :user, password: "password"

    factory :private_project do
      visible_to ["collaborator"]
    end

    factory :full_project do
      after(:create) do |p|
        workflow = create(:workflow, project: p)
        subject_set = create_list(:subject_set_with_subjects, 2, project: p, workflows: [workflow])
      end
    end

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
