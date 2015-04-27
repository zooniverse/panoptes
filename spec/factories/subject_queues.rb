# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subject_queue do
    user
    workflow
    subject_set
    set_member_subject_ids []
  end
end
