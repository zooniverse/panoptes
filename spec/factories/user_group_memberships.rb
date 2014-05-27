FactoryGirl.define do
  factory :user_group_membership do
    state { UserGroupMembership.states.keys.sample }
    user
    user_group
  end
end
