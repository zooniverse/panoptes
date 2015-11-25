FactoryGirl.define do
  factory :field_guide do
    language 'en'
    items [
      {title: "Page 1", content: "stuff and things", icon: '123456'},
      {title: "Other guide", content: "animals & such", icon: '654321'}
    ]
    project
  end
end
