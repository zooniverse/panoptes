FactoryGirl.define do
  factory :tag do
    name "MyText"
    transient do
      resource nil
    end

    before(:create) do |t, env|
      if env.resource
        t.tagged_resources.build(resource: env.resource)
      else
        t.tagged_resources.build(resource: create(:project))
      end
    end
  end
end
