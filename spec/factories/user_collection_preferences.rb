FactoryGirl.define do
  factory :user_collection_preference do
    preferences '{"display": "grid"}'
    roles []
    user
    collection
  end
end
