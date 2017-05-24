FactoryGirl.define do
  factory :organization do
    transient do
      build_contents true
      build_media false
    end

    sequence(:display_name) { |n| "Test Organization #{ n }" }
    listed_at Time.now
    listed true
    primary_language "en"
    urls [{"label" => "0.label", "url" => "http://blog.example.com/"}, {"label" => "1.label", "url" => "http://twitter.com/example"}]

    association :owner, factory: :user

    after(:build) do |o, env|
      if env.build_contents
        o.organization_contents << build_list(:organization_content, 1, organization: o, language: o.primary_language)
        o.organization_contents << build_list(:organization_content, 1, organization: o, language: 'en-US')
      end

      if env.build_media
        o.avatar = create(:medium, type: "organization_avatar", linked: o)
        o.background = create(:medium, type: "organization_background", linked: o)
      end
    end

    factory :unlisted_organization do
      listed_at nil
      listed false
    end
  end
end