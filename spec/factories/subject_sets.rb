FactoryGirl.define do
  factory :subject_set do
    name "A Subject set"
    project

    factory :subject_set_with_workflow do
      after(:create) do |sg|
        create_list(:workflow, 1, subject_sets: [sg])
      end
    end

    factory :subject_set_with_workflows do
      after(:create) do |sg|
        n = Array(2..10).sample
        create_list(:workflow, n, subject_sets: [sg])
      end
    end

    factory :subject_set_with_subjects do
      after(:create) do |sg|
        n = Array(20..100).sample
        create_list(:set_member_subject, n, subject_set: sg)
      end
    end
  end
end
