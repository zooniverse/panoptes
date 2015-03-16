FactoryGirl.define do
  factory :project, aliases: [:project_with_contents] do
    transient do
      build_contents true
      build_extra_contents false
    end

    sequence(:name) { |n| "test_project_#{ n }" }
    sequence(:display_name) { |n| "Test Project #{ n }" }
    user_count { 10 + rand(1000) }
    activated_state Project.activated_states[:active]
    primary_language "en"
    avatar "http://test.host/x02234.jpg.gif.png.webp"
    background_image "http://test.host/12312asd.jp2"
    private false

    association :owner, factory: :user

    after(:build) do |p, env|
      if env.build_contents
        p.project_contents << build_list(:project_content, 1, project: p, language: p.primary_language)
        if env.build_extra_contents
          p.project_contents << build_list(:project_content, 1, project: p, language: 'zh-TW')
          p.project_contents << build_list(:project_content, 1, project: p, language: 'en-US')
        end
      end
    end

    factory :private_project do
      private(true)
    end

    factory :full_project do
      after(:create) do |p|
        workflow = create(:workflow, project: p)
        subject_set = create_list(:subject_set_with_subjects, 2, project: p, workflow: workflow)
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
  end
end
