FactoryGirl.define do
  factory :classification do
    metadata({
              user_agent: "cURL",
              started_at: 2.minutes.ago.to_s,
              finished_at: 1.minute.ago.to_s,
              user_language: 'en',
             })
    annotations [{task: "an_annotation",
                  value: true},
                 {task: "another_one",
                  value: [1, 2]}]
    user_ip "192.168.0.1"
    workflow_version "15.15"
    completed true
    user
    project
    workflow
    subject_ids do
      create_list(:set_member_subject, 2).map(&:subject).map(&:id)
    end

    factory(:classification_with_recents) do
      after(:build) do |c|
        c.subject_ids.each do |sid|
          c.recents << build(:recent, classification: c, subject_id: sid)
        end
      end
    end

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

    factory :already_seen_classification do
      after(:build) do |c|
        c.metadata = c.metadata.merge(seen_before: "true")
      end

      factory :anonymous_already_seen_classification do
        user nil
      end
    end
  end
end
