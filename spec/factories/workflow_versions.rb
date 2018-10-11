FactoryBot.define do
  sequence(:workflow_version_major_version) { |n| n }
  sequence(:workflow_version_minor_version) { |n| n }

  factory :workflow_version do
    workflow
    major_version { generate :workflow_version_major_version }
    minor_version { generate :workflow_version_minor_version }
    first_task { attributes_for(:workflow)[:first_task] }
    tasks { attributes_for(:workflow)[:tasks] }
    strings { attributes_for(:workflow)[:strings] }
  end
end
