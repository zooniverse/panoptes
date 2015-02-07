FactoryGirl.define do
  factory :classification do
    metadata({
               user_agent: "CURL",
               started_at: 2.minutes.ago.to_s,
               finished_at: 1.minute.ago.to_s,
               workflow_version: "1.1",
               user_language: 'en',
             })
    annotations [{task: "an_annotation",
                  value: true},
                 {task: "another_one",
                  value: [1, 2]}]
    user_ip "192.168.0.1"
    completed true
    user
    project
    workflow
    set_member_subject_ids { create_list(:set_member_subject, 2).map(&:id) }

    factory :classifaction_with_user_group do
      user_group
    end

    factory :gold_standard_classification do
      expert_classifier :expert
      gold_standard true
    end

    factory :fake_gold_standard_classification do
      gold_standard false
    end
  end
end
