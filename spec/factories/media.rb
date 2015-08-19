FactoryGirl.define do
  sequence :loc_index, 1

  factory :medium do
    type "subject_location"
    association :linked, factory: :subject
    content_type "image/jpeg"
    path_opts ["1"]
    src "panoptes-uploads.zooniverse.org/1/1/#{SecureRandom.uuid}.jpeg"
    metadata { {index: generate(:loc_index) } }
  end
end
