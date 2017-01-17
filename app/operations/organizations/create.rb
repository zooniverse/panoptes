module Organizations
  class Create < Operation
    include UrlLabels

    string :name
    string :display_name
    string :primary_language

    # Organization Contents Fields
    string :title
    string :description
    string :introduction, default: ''
    array :urls, default: ''

    def execute
      Organization.transaction do
        organization = Organization.new owner: api_user.user, name: name, display_name: display_name, primary_language: primary_language
        param_hash = { title: title, description: description, introduction: introduction }
        param_hash.merge! content_from_params(inputs, Api::V1::OrganizationsController::CONTENT_FIELDS)
        organization.organization_contents.build param_hash
        organization.save!
        organization
      end
    end
  end
end
