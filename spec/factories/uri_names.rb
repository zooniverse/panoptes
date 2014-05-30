# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :uri_name do
    sequence(:name) {|n| "MyString_#{n}"}
    
    factory :uri_name_for_user do
      association :resource, factory: :user, password: "password"
    end

    factory :uri_name_for_group do
      association :resource, factory: :user_group
    end
  end
end
