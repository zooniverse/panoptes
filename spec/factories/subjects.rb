FactoryGirl.define do
  factory :subject do
    project
    sequence(:zooniverse_id) { |n| "TES#{n.to_s(26).rjust(8, '0')}" }
    metadata({distance_from_earth: "42 light years",
              brightness: -20,
              loudness: 11})
    locations([ {"image/jpeg" => "panoptes-uploads.zooniverse.org/1/1/#{SecureRandom.uuid}.jpeg"} ])

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

    factory :migrated_project_subject do
      locations({standard: "http://www.galaxyzoo.org.s3.amazonaws.com/subjects/standard/1237679543502373086.jpg"})
      migrated true
    end
  end
end
