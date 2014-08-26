FactoryGirl.define do
  factory :membership do
    state { Membership.states.keys.sample }
    roles []
    user
    user_group
  end
end
