FactoryGirl.define do
  factory :subject_set do
    sequence(:display_name) { |n| "Subject Set #{n}" }

    metadata({ just_some: "stuff" })
    project

    after(:create) do |ss|
      create_list(:workflow, 1, subject_sets: [ss])
    end

    factory :subject_set_with_subjects do
      after(:create) do |sg|
        create_list(:set_member_subject, 2, subject_set: sg)
      end
    end
  end
end
