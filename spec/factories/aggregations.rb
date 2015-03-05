FactoryGirl.define do
  factory :aggregation do
    workflow
    subject
    aggregation({ data: "goes here", workflow_version: "1.1" })
  end
end
