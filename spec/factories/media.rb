FactoryGirl.define do
  factory :medium do
    type "subject_location"
    association :linked, factory: :subject
    content_type "image/jpeg"
    src "panoptes-uploads.zooniverse.org/1/1/#{SecureRandom.uuid}.jpeg"
  end

end
