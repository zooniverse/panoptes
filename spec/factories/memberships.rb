FactoryGirl.define do
  factory :membership do
    state { Membership.states.keys.sample }
    user
    user_group
  end
end
