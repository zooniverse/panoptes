FactoryBot.define do
  factory :subject_set_import do
    subject_set
    user
    source_url 'https://example.org/source_url.csv'
  end
end
