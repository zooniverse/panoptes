FactoryGirl.define do
  factory :subject_workflow_count do
    transient do
      link_subject_sets true
    end
    subject
    workflow
    classifications_count 1

    after(:build) do |swc, env|
      if env.link_subject_sets && swc.workflow && swc.workflow.subject_sets.empty?
        swc.workflow.subject_sets += swc.subject.subject_sets
      end
    end
  end
end
