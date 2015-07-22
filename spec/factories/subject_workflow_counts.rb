FactoryGirl.define do
  factory :subject_workflow_count do
    set_member_subject
    workflow
    classifications_count 1

    after(:build) do |swc|
      if swc.workflow.subject_sets.empty?
        swc.workflow.subject_sets << swc.set_member_subject.subject_set
      end
    end
  end
end
