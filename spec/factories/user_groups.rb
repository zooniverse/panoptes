FactoryBot.define do
  factory :user_group do
    sequence(:name){ |n| "user_group_#{ n }" }
    display_name{ name.try :titleize }
    activated_state { :active }

    transient do
      admin { nil }
    end

    after :create do |user_group, evaluator|
      if evaluator.admin.present?
        create :membership, state: Membership.states[:active],
               roles: ['group_admin'],
               user: evaluator.admin,
               user_group: user_group
      end
    end

    factory :user_group_with_users do
      after(:create) do |ug|
        create_list(:membership, 2, state: Membership.states[:active],
                    roles: ["group_admin"], user_group: ug)
      end
    end

    factory :identity_user_group do
      after(:create) do |ug|
        create_list(:membership, 1, state: Membership.states[:active],
                    roles: ["group_admin"], user_group: ug, identity: true)
      end
    end

    factory :user_group_with_projects do
      after(:create) do |ug|
        create_list(:project, 2, owner: ug)
      end
    end

    factory :user_group_with_collections do
      after(:create) do |ug|
        create_list(:collection, 2, owner: ug)
      end
    end
  end
end
