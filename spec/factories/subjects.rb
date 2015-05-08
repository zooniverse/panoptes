FactoryGirl.define do
  factory :subject do
    project
    upload_user_id "1"

    sequence(:zooniverse_id) { |n| "TES#{n.to_s(26).rjust(8, '0')}" }
    metadata({distance_from_earth: "42 light years",
              brightness: -20,
              loudness: 11})

    after(:create) do |s|
      create_list(:medium, 2, linked: s)
    end

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
