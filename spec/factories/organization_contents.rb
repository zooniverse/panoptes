FactoryGirl.define do
  factory :organization_content do
    organization
    description "This is the description for an Organization"
    title "Test Organization"
    introduction "This is the intro for an Organization"
    announcement "Alert: This organization has something to let you know"
    language "en"
    url_labels({"0.label" => "Blog", "1.label" => "Twitter"})
  end
end
