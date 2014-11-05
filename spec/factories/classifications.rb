FactoryGirl.define do
  factory :classification do
    metadata({user_agent: "CURL",
              started_at: 2.minutes.ago,
              finished_at: Time.now})
    annotations [{an_annotation: true},
                 {another_one: [1, 2]}]
    user_ip "192.168.0.1"
    completed true
    user
    project
    workflow
    set_member_subject

    factory :classifaction_with_user_group do
      user_group
    end
  end
end
