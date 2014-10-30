# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :workflow_content do
    workflow 
    language "en"
    strings ['Draw a circle',
             'Red',
             'Green',
             'Blue',
             'What shape is this galaxy',
             'Smooth',
             'Features',
             'Star or artifact']
  end
end
