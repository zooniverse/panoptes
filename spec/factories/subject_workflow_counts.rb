FactoryGirl.define do
  factory :subject_workflow_count do
    set_member_subject
    workflow
    classifications_count 1
  end
end
