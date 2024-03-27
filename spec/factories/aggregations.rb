FactoryBot.define do
  factory :aggregation do
    workflow
    user
    status { Aggregation.statuses[:pending] }
  end
end
