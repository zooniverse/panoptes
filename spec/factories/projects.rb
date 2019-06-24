FactoryBot.define do
  factory :project, aliases: [:project_with_contents] do
    sequence(:name) { |n| "test_project_#{ n }" }
    sequence(:display_name) { |n| "Test Project #{ n }" }
    user_count { 10 + rand(1000) }
    activated_state Project.activated_states[:active]
    configuration { { x: "y", z: "q" } }
    primary_language "en"
    private false
    launch_approved true
    launched_row_order_position { rand(0..100).to_i }
    beta_row_order_position { rand(0..100).to_i }
    live false
    urls [{"label" => "0.label", "url" => "http://blog.example.com/"}, {"label" => "1.label", "url" => "http://twitter.com/example"}]

    description "Some Lorem Ipsum"
    introduction "MORE IPSUM"
    workflow_description "Go outside"
    researcher_quote "This is my favorite project"
    url_labels({"0.label" => "Blog", "1.label" => "Twitter", "2.label" => "Science Case"})

    association :owner, factory: :user

    factory :private_project do
      private(true)
    end

    factory :full_project do
      after(:create) do |p|
        p.avatar = create(:medium, type: "project_avatar", linked: p)
        p.background = create(:medium, type: "project_background", linked: p)
        p.workflows = [ create(:workflow_with_subjects, project: p) ]
      end
    end

    factory :project_with_workflow do
      after(:create) do |p|
        workflow = create(:workflow, project: p)
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
