FactoryGirl.define do
  factory :user_group do
    sequence(:name) { |n| "a_user_group_#{n}" }
    display_name "A User Group"
    classification_count { 10 + rand(1000) }

    factory :user_group_with_users do
      after(:create) do |ug|
        n = Array(20..100).sample
        create_list(:user_group_membership, n, user_group: ug)
      end
    end
  end
end
