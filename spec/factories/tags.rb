FactoryGirl.define do
  factory :tag do
    transient do
      resource nil
    end

    sequence(:name) { |n| "tag-#{n}" }

    before(:create) do |t, env|
      if env.resource
        t.tagged_resources.build(resource: env.resource)
      else
        t.tagged_resources.build(resource: create(:project))
      end
    end
  end
end
