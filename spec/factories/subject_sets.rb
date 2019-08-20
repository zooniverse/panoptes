FactoryBot.define do
  factory :subject_set do
    transient do
      num_workflows { 1 }
      num_subjects { 2 }
    end

    sequence(:display_name) { |n| "Subject Set #{n}" }

    metadata { { just_some: "stuff" } }
    project

    after(:create) do |ss, evaluator|
      if ss.workflows.empty? && evaluator.num_workflows
        create_list(:workflow, evaluator.num_workflows, subject_sets: [ss], project: ss.project)
      end
    end

    factory :subject_set_with_subjects do
      after(:create) do |set, evaluator|
        evaluator.num_subjects.times do |i|
          subject = create(:subject, project: set.project, uploader: set.project.owner)
          create(:set_member_subject, subject_set: set, subject: subject)
        end
        set.set_member_subjects_count = set.set_member_subjects.count
      end
    end
  end
end
