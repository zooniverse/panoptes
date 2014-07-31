# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_collection_preference do
    roles "MyString"
    preferences ""
    roles "MyString"
    user
    collection
  end
end
