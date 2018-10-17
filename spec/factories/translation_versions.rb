FactoryBot.define do
  factory :translation_version do
    strings({title: "Hello"})
    versions({title: 1})
  end
end
