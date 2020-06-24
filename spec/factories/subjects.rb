FactoryBot.define do
  factory :subject do
    project
    association :uploader, factory: :user

    sequence(:zooniverse_id) { |n| "TES#{n.to_s(26).rjust(8, '0')}" }
    metadata { {distance_from_earth: "42 light years",
              brightness: -20,
              loudness: 11} }

    trait :with_mediums do
      transient do
        num_media { 2 }
      end

      after :create do |s, evaluator|
        create_list(:medium, evaluator.num_media, linked: s)
      end
    end

    trait :with_collections do
      after(:create) do |s|
        create_list(:collection, 2, subjects: [s])
      end
    end

    trait :with_subject_sets do
      transient do
        num_sets { 2 }
      end

      after(:create) do |s, evaluator|
        evaluator.num_sets.times do |i|
          create(:set_member_subject, subject: s, subject_set: create(:subject_set, project: s.project))
        end
      end
    end
  end
end
