FactoryGirl.define do
  factory :tagged_resource do
    tag
    association :resource, factory: :project
  end
end
