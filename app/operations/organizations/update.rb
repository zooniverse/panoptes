module Organizations
  class Update < Operation
    include UrlLabels

    integer :id
    string :name
    string :display_name
    string :primary_language

    # Organization Contents Fields
    string :title
    string :description
    string :introduction, default: ''
    array :urls

    def execute
      Organization.transaction do
        organization = Organization.find(id)
        organization.update!(name: name, display_name: display_name, primary_language: primary_language)
        organization.organization_contents.find_or_initialize_by(language: primary_language) do |content|
          param_hash = { title: title, description: description, introduction: introduction }
          param_hash.merge! content_from_params(inputs, Api::V1::OrganizationsController::CONTENT_FIELDS)
          content.update! param_hash
        end
        organization.save!
      end
    end
  end
end
