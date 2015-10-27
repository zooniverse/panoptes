FactoryGirl.define do
  factory :collection do
    transient do
      build_projects true
    end
    sequence(:name) { |n| "collection_name_#{ n }" }
    sequence(:display_name) { |n| "another name #{ n }" }
    activated_state :active
    private false

    association :owner, factory: :user

    project_ids do
      if build_projects
        [ create(:project).id ]
      else
        (1..10).to_a.sample(2)
      end
    end

    factory :private_collection do
      private true
    end

    factory :collection_with_subjects do
      after(:create) do |col|
        create_list(:subject, 2, collections: [col], project: col.projects.sample)
      end
    end
  end
end
