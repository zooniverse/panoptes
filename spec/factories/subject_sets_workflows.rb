FactoryGirl.define do
  factory :subject_sets_workflow do
    workflow
    association :subject_set, factory: :subject_set_with_subjects
  end
end
