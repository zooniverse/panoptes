FactoryBot.define do
  factory :organization do
    transient do
      build_contents true
      build_media false
    end

    sequence(:display_name) { |n| "Test Organization #{ n }" }
    listed_at Time.now
    listed true
    primary_language "en-gb"
    urls [{"label" => "0.label", "url" => "http://blog.example.com/"}, {"label" => "1.label", "url" => "http://twitter.com/example"}]
    categories %w(bugs fossils plants)

    description "This is the description for an Organization"
    introduction "This is the intro for an Organization"
    announcement "Alert: This organization has something to let you know"
    url_labels({"0.label" => "Blog", "1.label" => "Twitter"})

    association :owner, factory: :user

    after(:build) do |o, env|
      if env.build_contents
        o.organization_contents << build_list(:organization_content, 1, organization: o, language: o.primary_language)
        o.organization_contents << build_list(:organization_content, 1, organization: o, language: 'en-US')
      end

      if env.build_media
        o.avatar = create(:medium, type: "organization_avatar", linked: o)
        o.background = create(:medium, type: "organization_background", linked: o)
        o.attached_images << create(:medium, type: "organization_attached_image", linked: o)
      end
    end

    factory :unlisted_organization do
      listed_at nil
      listed false
    end
  end
end
