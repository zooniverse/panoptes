module Organizations
  class Create < Operation
    string :name
    string :display_name
    string :primary_language

    # Organization Contents Fields
    string :title
    string :description
    string :introduction, default: ''

    def execute
      Organization.transaction do
        organization = Organization.new owner: api_user.user, name: name, display_name: display_name, primary_language: primary_language
        organization.organization_contents.build title: title, description: description, introduction: introduction, language: primary_language
        organization.save!
        organization
      end
    end
  end
end
