# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_seen_subject do
    user
    workflow
    subject_ids { create_list(:set_member_subject, 2).map(&:subject).map(&:id) }
  end
end
