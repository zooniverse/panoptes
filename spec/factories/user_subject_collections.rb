FactoryGirl.define do
  factory :user_subject_collection do

    project
    association :owner, factory: :user

    factory :user_subject_collection_with_subjects do
      after(:create) do |col|
        n = Array(2..100).sample
        create_list(:subjects, n, collections: [col])
      end
    end
  end
end
