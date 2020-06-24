FactoryBot.define do
  factory :gold_standard_annotation do
    metadata { 
      {
        user_agent: "cURL",
        started_at: 2.minutes.ago.to_s,
        finished_at: 1.minute.ago.to_s,
        user_language: 'en'
      }
     }
    annotations { 
      [
        {task: "an_annotation", value: true},
        {task: "another_one", value: [1, 2]}
      ]
     }
    project
    workflow
    subject
    user

    after(:build) do |gsa, evaluator|
      gsa.classification = create(:classification,
        project: gsa.project,
        workflow: gsa.workflow,
        user: gsa.user,
        subjects: [gsa.subject]
      )
    end
  end
end
