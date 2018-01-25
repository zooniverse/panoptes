FactoryBot.define do
  factory :application, class: Doorkeeper::Application do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri 'urn:ietf:wg:oauth:2.0:oob'
    default_scope ['public', 'project', 'classification']
    trust_level 0
    owner { build :user }

    factory :first_party_app do
      trust_level 2
    end

    factory :secure_app do
      trust_level 1
    end
  end
end
