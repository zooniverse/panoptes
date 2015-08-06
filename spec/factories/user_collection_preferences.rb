FactoryGirl.define do
  factory :user_collection_preference do
    transient do
      public false
    end

    user { create(:user, private_profile: !public) }
    preferences '{"display": "grid"}'
    collection
  end
end
