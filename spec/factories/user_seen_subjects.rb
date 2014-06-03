# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_seen_subject do
    user
    workflow
    subject_zooniverse_ids ["ZOO00000001", "ZOO00000002", "ZZOO00000003"]
  end
end
