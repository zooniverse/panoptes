FactoryGirl.define do
  factory :organization_content do
    sequence(:description) { |n| "This is the description for Organization #{ n }" }
    sequence(:title) { |n| "Test Organization #{ n }" }
    sequence(:introduction) { |n| "This is the intro for Organization #{ n }" }
    language "tw"
  end
end