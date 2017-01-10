module Organizations
  class Create < Operation
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
        organization = Organization.new owner: api_user.user, name: name, display_name: display_name, primary_language: primary_language
        param_hash = { title: title, description: description, introduction: introduction }
        param_hash.merge! content_from_params(inputs)
        # organization.organization_contents.build title: title, description: description, introduction: introduction, language: primary_language, urls: contenturls
        organization.organization_contents.build param_hash
        organization.save!
        organization
      end
    end


  end
end
