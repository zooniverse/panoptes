FactoryGirl.define do
  factory :collection do
    sequence(:name) { |n| "collection_name_#{ n }" }
    sequence(:display_name) { |n| "another name #{ n }" }
    sequence(:description) { |n| "This collection is SO GOOD, it is #{ n } times better than any other" }
    activated_state :active
    private false

    association :owner, factory: :user

    project_ids do
      [ create(:project).id ]
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
