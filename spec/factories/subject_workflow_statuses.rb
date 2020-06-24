FactoryBot.define do
  factory :subject_workflow_status do
    transient do
      link_subject_sets { true }
    end
    association :subject, :with_subject_sets, num_sets: 1
    workflow
    classifications_count { 1 }

    after(:build) do |sws, env|
      if env.link_subject_sets && sws.workflow && sws.workflow.subject_sets.empty?
        sws.workflow.subject_sets += sws.subject.subject_sets
      end
    end
  end
end
