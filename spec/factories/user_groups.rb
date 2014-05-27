FactoryGirl.define do
  factory :user_group do
    sequence(:name) { |n| "a_user_group_#{n}" }
    display_name "A User Group"
    classification_count { 10 + rand(1000) }

    factory :user_group_with_users do
      after(:create) do |ug|
        create_list(:user_group_membership, 10, user_group: ug)
      end
    end
  end
end
