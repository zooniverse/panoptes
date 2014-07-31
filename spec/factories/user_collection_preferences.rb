# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_collection_preference, :class => 'UserCollectionPreferences' do
    roles "MyString"
    preferences ""
    roles "MyString"
    user nil
    collection nil
  end
end
