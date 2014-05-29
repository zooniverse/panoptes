FactoryGirl.define do
  factory :subject do
    sequence(:zooniverse_id) { |n| "TES#{n.to_s(26).rjust(8, '0')}" }
    metadata Hash.new(distance_from_earth: "42 light years",
              brightness: -20,
              loudness: 11).to_json
    locations Hash.new(main_image: "http://example.com/main_image.png").to_json

    factory :subject_with_collections do
      after(:create) do |s|
        n = Array(20..150).sample
        create_list(:collection, n, subjects: [s])
      end
    end

    factory :subject_with_subject_sets do
      after(:create) do |s|
        n = Array(10..20).sample
        create_list(:set_member_subject, n, subject: s)
      end
    end
  end
end
