FactoryGirl.define do
  factory :classification do
    annotations [{an_annotation: true,
                  another_one: [1, 2]}].to_json
    user
    project
    workflow
    set_member_subject

      factory :classifaction_with_user_group do
        user_group
      end
  end
end
