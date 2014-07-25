# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :workflow_content do
    workflow 
    language "en"
    strings '{ "question_key" : { "string" : "question string?", "tutorial" : "tutorial string", "answer_key1" : "answer1 string", "answer_key2": "answer2 string" }}'
  end
end
