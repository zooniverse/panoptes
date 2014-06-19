# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project_content do
    project
    language "en"
    title "A Test Project"
    description "Some Lorem Ipsum"
    pages '{ "about": {"title": "A Page Title", "content_html": "<p>Some HTML Cotent</p>", "content_md": "Some Markdown Content"} }'
    example_strings '{ "example_1": "A descripton of it"}' 
    task_strings '{"question_key": {"question": "Question Text", "answers": {"answer_key": "answer text"}}}'
  end
end
