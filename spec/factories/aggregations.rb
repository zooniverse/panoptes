FactoryBot.define do
  factory :aggregation do
    workflow
    project
    user
    status { Aggregation.statuses[:pending] }
  end
end
