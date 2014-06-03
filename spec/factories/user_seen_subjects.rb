# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_seen_subject do
    user
    workflow
    subject_ids [1,2,3]
  end
end
