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
    array :categories, default: []
    array :tags, default: []

    def execute
      Organization.transaction(requires_new: true) do
        organization = build_organization
        organization.organization_contents.build(organization_contents_params)

        tag_objects = Tags::BuildTags.run!(api_user: api_user, tag_array: tags) if tags
        organization.tags = tag_objects unless tags.nil?

        organization.save!
        organization
      end
    end

    private

    def build_organization
      Organization.new(
        owner: api_user.user,
        display_name: display_name,
        primary_language: primary_language,
        categories: categories
      )
    end

    def organization_contents_params
      organization_contents_params = {
        title: display_name,
        description: description,
        introduction: introduction
      }
      organization_contents_params.merge(
        organization_contents_from_params
      )
    end

    def organization_contents_from_params
      content_from_params(
        inputs,
        Api::V1::OrganizationsController::CONTENT_FIELDS
      )
    end
  end
end
