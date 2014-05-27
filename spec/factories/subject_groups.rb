FactoryGirl.define do
  factory :subject_group do
    name "A Subject Group"
    project

    factory :subject_group_with_workflow do
      after(:create) do |sg|
        create_list(:workflow, 1, subject_groups: [sg])
      end
    end

    factory :subject_group_with_workflows do
      after(:create) do |sg|
        n = Array(2..10).sample
        create_list(:workflow, n, subject_groups: [sg])
      end
    end
  end
end
