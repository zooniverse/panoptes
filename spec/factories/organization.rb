FactoryGirl.define do
  factory :organization do
    sequence(:name) { |n| "test_org_#{ n }" }
    sequence(:display_name) { |n| "Test Organization #{ n }" }
    listed_at Time.now
    primary_language "en"
    urls [{"label" => "0.label", "url" => "http://blog.example.com/"}, {"label" => "1.label", "url" => "http://twitter.com/example"}]

    association :owner, factory: :user

    after(:build) do |o|
      o.organization_contents << build_list(:organization_content, 1, organization: o, language: o.primary_language)
      o.organization_contents << build_list(:organization_content, 1, organization: o, language: 'sp')
    end
  end
end