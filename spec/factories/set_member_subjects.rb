FactoryBot.define do
  factory :set_member_subject do
    subject_set
    subject

    trait :with_priorities do
      sequence(:priority)
      subject_set { subject_set }
    end

    transient do
      setup_subject_workflow_statuses false
    end

    after(:create) do |sms, env|
      SubjectSet.where(id: sms.subject_set_id)
        .update_all("set_member_subjects_count = set_member_subjects_count + 1")

      if env.setup_subject_workflow_statuses
        SubjectWorkflowStatus.create!(
          subject_id: sms.subject_id,
          workflow_id: sms.workflows.first.id
        )
      end
    end
  end
end
