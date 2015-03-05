FactoryGirl.define do
  factory :zooniverse_user do
    sequence(:login) { |n| "zoo_user_#{n}" }
    sequence(:email) { |n| "zoo_user_#{n}@example.com" }
    persistence_token "asdfasd"
    single_access_token "asdfasdf"
    perishable_token "asdfasd"
    password 'tajikistan'
  end
end
