FactoryGirl.define do
  factory :workflow do
    name "A Workflow"
    tasks(
      {
        interest: {
          type: "draw",
          question: 0,
          next: "shape",
          tools: [
            {value: "red", label: 1, type: 'point', color: 'red'},
            {value: "green", label: 2, type: 'point', color: 'lime'},
            {value: "blue", label: 3, type: 'point', color: 'blue'},
          ]
        },
        shape: {
          type: 'multiple',
          question: 4,
          answers: [
            {value: 'smooth', label: 5},
            {value: 'features', label: 6},
            {value: 'other', label: 7}
          ],
          next: nil
        }
      }
    )
    pairwise false
    grouped false
    prioritized false
    primary_language 'en-US'
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

    factory :workflow_with_contents do
      after(:create) do |w|
        create_list(:workflow_content, 1, workflow: w, language: w.primary_language)
      end
    end
  end
end
