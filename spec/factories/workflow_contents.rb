# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :workflow_content do
    workflow 
    language "en"
    strings ['a string', 'another string']
  end
end
