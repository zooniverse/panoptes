# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_enqueued_subject do
    user
    workflow
    subject_ids []
  end
end
