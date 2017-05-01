module Organizations
  class Create < Operation
    include UrlLabels
    include ContentFromParams

    string :display_name
    string :primary_language

    # Organization Contents Fields
    string :description
    string :introduction, default: ''
    array :urls, default: []

    def execute
      Organization.transaction do
        organization = Organization.new owner: api_user.user, display_name: display_name, primary_language: primary_language
        param_hash = { title: display_name, description: description, introduction: introduction }
        param_hash.merge! content_from_params(inputs, Api::V1::OrganizationsController::CONTENT_FIELDS)
        organization.organization_contents.build param_hash
        organization.save!
        organization
      end
    end
  end
end
