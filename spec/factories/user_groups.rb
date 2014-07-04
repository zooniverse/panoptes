FactoryGirl.define do
  factory :user_group do
    display_name "A User Group"
    activated_state :active

    factory :user_group_with_users do
      display_name "A User Group With Users"
      after(:create) do |ug|
        create_list(:membership, 2, user_group: ug)
      end
    end

    factory :user_group_with_projects do
      display_name "A User Group With Projects"
      after(:create) do |ug|
        create_list(:project, 2, owner: ug)
      end
    end

    factory :user_group_with_collections do
      display_name "A User Group With Collections"
      after(:Create) do |ug|
        create_list(:collections, 2, owner: ug)
      end
    end
  end
end
