FactoryGirl.define do
  factory :user_collection_preference do
    preferences '{"display": "grid"}'
    user
    collection
  end
end
