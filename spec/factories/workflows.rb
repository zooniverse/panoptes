FactoryGirl.define do
  factory :workflow do
    name "A Workflow"
    tasks [{we_need: "an_example"},
           {of_some_tasks: "blerg!"}].to_json
    pairwise false
    grouped false
    prioritized false
    project

    factory :workflow_with_subject_set do
      after(:create) do |w|
        create_list(:subject_set, 1, workflows: [w])
      end
    end

    factory :workflow_with_subject_sets do
      after(:create) do |w|
        create_list(:subject_set, 2, workflows: [w])
      end
    end

    factory :workflow_with_subjects do
      after(:create) do |w|
        create_list(:subject_set_with_subjects, 2, workflows: [w])
      end
    end
  end
end
