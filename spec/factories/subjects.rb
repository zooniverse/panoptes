FactoryGirl.define do
  factory :subject do
    sequence(:zooniverse_id) { |n| "TES" + "%08d" % n.to_s(26) }
    metadata Hash.new(distance_from_earth: "42 light years",
              brightness: -20,
              loudness: 11).to_json
    locations Hash.new(main_image: "http://example.com/main_image.png").to_json
  end
end
