FactoryBot.define do
  factory :aggregation do
    workflow
    user
    uuid { SecureRandom.uuid }
    task_id { SecureRandom.uuid }
  end
end
