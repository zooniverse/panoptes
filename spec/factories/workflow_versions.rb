FactoryBot.define do
  sequence(:workflow_version_major_number) { |n| n }
  sequence(:workflow_version_minor_number) { |n| n }

  factory :workflow_version do
    workflow
    major_number { generate :workflow_version_major_number }
    minor_number { generate :workflow_version_minor_number }
    first_task { attributes_for(:workflow)[:first_task] }
    tasks { attributes_for(:workflow)[:tasks] }
    strings { attributes_for(:workflow)[:strings] }
  end
end
