FactoryGirl.define do
  factory :workflow, aliases: [:workflow_with_contents] do
    transient do
      build_contents true
      build_extra_contents false
    end

    display_name "A Workflow"

    first_task "interest"
    tasks(
      {
        interest: {
          type: 'drawing',
          question: "interest.question",
          help: "interest.help",
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
          help: "shape.help",
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
    retired_set_member_subjects_count 0

    after(:build) do |w, env|
      if env.build_contents
        w.workflow_contents << build_list(:workflow_content, 1, workflow: w, language: w.primary_language)
        if env.build_extra_contents
        w.workflow_contents << build_list(:workflow_content, 1, workflow: w, language: 'en-US')
        w.workflow_contents << build_list(:workflow_content, 1, workflow: w, language: 'zh-TW')
        end
      end
    end

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
