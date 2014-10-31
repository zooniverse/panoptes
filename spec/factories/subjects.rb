FactoryGirl.define do
  factory :subject do
    association :owner, factory: :user
    project
    sequence(:zooniverse_id) { |n| "TES#{n.to_s(26).rjust(8, '0')}" }
    metadata({distance_from_earth: "42 light years",
              brightness: -20,
              loudness: 11})
    locations({main_image: "image/jpeg"})

    factory :subject_with_collections do
      after(:create) do |s|
        create_list(:collection, 2, subjects: [s])
      end
    end

    factory :subject_with_subject_sets do
      after(:create) do |s|
        create_list(:set_member_subject, 2, subject: s)
      end
    end
  end
end
