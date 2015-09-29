FactoryGirl.define do
  factory :set_member_subject do
    subject_set
    subject

    trait :with_priorities do
      sequence(:priority)
    end

    after(:create) do |sms|
      SubjectSet.where(id: sms.subject_set_id)
        .update_all("set_member_subjects_count = set_member_subjects_count + 1")
    end
  end
end
