FactoryBot.define do
  factory :membership do
    state { :active }
    roles { ["group_member"] }
    user
    user_group
  end
end
