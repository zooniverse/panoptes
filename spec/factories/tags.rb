FactoryGirl.define do
  factory :tag do
    name "MyText"

    before(:create) do |t| 
      t.tagged_resources << build(:tagged_resource, tag: t)
    end
  end
end
