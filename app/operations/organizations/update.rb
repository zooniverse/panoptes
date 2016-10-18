module Organizations
  class Update < Operation
    integer :id
    string :name
    string :display_name
    string :primary_language

    # Organization Contents Fields
    string :title
    string :description
    string :introduction, default: ''

    def execute
      Organization.transaction do
        organization = Organization.find(id)
        organization.update!(name: name, display_name: display_name, primary_language: primary_language)
        organization.organization_contents.find_or_initialize_by(language: primary_language) do |content|
          content.update! title: title, description: description, introduction: introduction
        end
        organization.save!
      end
    end
  end
end
