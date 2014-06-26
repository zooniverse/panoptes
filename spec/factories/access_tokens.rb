FactoryGirl.define do
  factory :access_token, class: Doorkeeper::AccessToken do
    sequence(:resource_owner_id) { |n| n }
    sequence(:application_id) { |n| n }
    expires_in 2.hours
    revoked_at nil

    factory :limitless_token do
      expires_in nil
    end

    factory :expired_token do
      expires_in -100
    end

    factory :revoked_token do
      revoked_at DateTime.yesterday.beginning_of_day
    end
  end
end
