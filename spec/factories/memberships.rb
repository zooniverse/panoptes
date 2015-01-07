FactoryGirl.define do
  factory :membership do
    state { Membership.states.keys.sample }
    roles ["group_member"]
    user
    user_group
  end
end
