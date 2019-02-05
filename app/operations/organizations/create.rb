module Organizations
  class Create < Operation
    string :display_name
    string :primary_language

    string :description
    string :introduction, default: ''
    string :announcement, default: ''
    array :urls, default: []
    array :categories, default: []
    array :tags, default: []

    def execute
      Organization.transaction(requires_new: true) do
        organization = build_organization

        tag_objects = Tags::BuildTags.run!(api_user: api_user, tag_array: tags) if tags
        organization.tags = tag_objects unless tags.nil?

        organization.save!
        organization
      end
    end

    private

    def build_organization
      Organization.new({
        owner: api_user.user,
        display_name: display_name,
        primary_language: primary_language,
        categories: categories,
        urls: urls_without_labels,
        url_labels: url_labels,
        description: description,
        introduction: introduction,
        announcement: announcement
      })
    end

    def organization_contents_params
      organization_contents_params = {
        title: display_name,
        description: description,
        introduction: introduction,
        announcement: announcement
      }
      organization_contents_params.merge(
        organization_contents_from_params
      )
    end

    def organization_contents_from_params
      fields = Api::V1::OrganizationsController::CONTENT_FIELDS
      ContentFromParams.content_from_params(inputs, fields)
    end

    def urls_without_labels
      urls_without_labels, _ = extract_url_labels
      urls_without_labels
    end

    def url_labels
      _, url_labels = extract_url_labels
      url_labels
    end

    def extract_url_labels
      @extract_url_labels ||= UrlLabels.extract_url_labels(urls)
    end
  end
end
