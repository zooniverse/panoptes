FactoryGirl.define do
  factory :workflow do
    display_name "A Workflow"

    first_task "interest"
    tasks(
      {
        interest: {
          type: 'drawing',
          question: "interest.question",
          tools: [
            {value: 'red', label: "interest.tools.0.label", type: 'point', color: 'red'},
            {value: 'green', label: "interest.tools.1.label", type: 'point', color: 'lime'},
            {value: 'blue', label: "interest.tools.2.label", type: 'point', color: 'blue'}
          ],
          next: 'shape'
        },
        shape: {
          type: 'multiple',
          question: "shape.question",
          answers: [
            {value: 'smooth', label: "shape.answers.0.label"},
            {value: 'features', label: "shape.answers.1.label"},
            {value: 'other', label: "shape.answers.2.label"}
          ],
          required: true,
          next: 'roundness'
        }
      }
    )
    
    pairwise false
    grouped false
    prioritized false
    primary_language 'en'
    project

    factory :workflow_with_subject_set do
      after(:create) do |w|
        create_list(:subject_set, 1, workflow: w)
      end
    end

    factory :workflow_with_subject_sets do
      after(:create) do |w|
        create_list(:subject_set, 2, workflow: w)
      end
    end

    factory :workflow_with_subjects do
      after(:create) do |w|
        create_list(:subject_set_with_subjects, 2, workflow: w)
      end
    end

    factory :workflow_with_contents do
      after(:create) do |w|
        create_list(:workflow_content, 1, workflow: w, language: w.primary_language)
      end
    end
  end
end
