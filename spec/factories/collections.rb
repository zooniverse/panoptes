FactoryGirl.define do
  factory :collection do
    name "collection_name"
    activated_state :active
    visibility "public"

    project
    association :owner, factory: :user

    factory :collection_with_subjects do
      after(:create) do |col|
        n = Array(2..100).sample
        create_list(:subject, n, collections: [col])
      end
    end
  end
end
