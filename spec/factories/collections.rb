FactoryGirl.define do
  factory :collection do
    name "collection_name"
    activated_state :active
    visibility "public"

    project
    association :owner, factory: :user

    factory :collection_with_subjects do
      after(:create) do |col|
        create_list(:subject, 2, collections: [col])
      end
    end
  end
end
