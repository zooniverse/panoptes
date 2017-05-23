FactoryGirl.define do
  factory :classifications_export_segment do
    workflow
    project { workflow.project }
    requester { project.owner }

    first_classification do
      create :classification,
            workflow: workflow,
            user: nil
    end

    last_classification do
      create :classification,
            workflow: workflow,
            user: nil,
            subject_ids: first_classification.subject_ids
    end
  end
end
