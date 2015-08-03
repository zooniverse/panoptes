FactoryGirl.define do
  factory :set_member_subject do
    subject_set
    subject

    trait :with_priorities do
      sequence(:priority)
    end
  end
end
