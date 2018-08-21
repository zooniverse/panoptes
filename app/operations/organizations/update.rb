require_relative '../../../lib/filters/organization_filter.rb'

module Organizations
  class Update < Operation
    organization :organization_params
    string :id

    def execute
      Organization.transaction(requires_new: true) do
        content_update = {}
        org_update = organization_params.dup
        Api::V1::OrganizationsController::CONTENT_FIELDS.each do |field|
          if organization_params[field]
            content_update[field] = organization_params[field] if organization_params[field]
            org_update.delete(field)
          end
        end

        if org_update.key?(:tags)
          tags = Tags::BuildTags.run!(api_user: api_user, tag_array: org_update[:tags])
          organization.tags = tags unless tags.nil?
          org_update.delete(:tags)
        end

        content_update.merge! content_params
        org_update.merge!(content_update.with_indifferent_access.except(:title, :language))

        organization.update!(org_update.symbolize_keys)
        organization.organization_contents.find_or_initialize_by(language: language).tap do |content|
          content.update! content_update.symbolize_keys
        end
        org_update[:listed] == true ? organization.touch(:listed_at) : organization[:listed_at] = nil

        organization.save!
        organization
      end
    end

    private

    def organization
      @organization ||= Organization.find(id)
    end

    def language
      @language ||= organization_params[:primary_language] ? organization_params[:primary_language] : @organization.primary_language
    end

    def content_params
      params = inputs[:organization_params].merge("title" => organization_params["display_name"])
      fields = Api::V1::OrganizationsController::CONTENT_FIELDS
      @content_params ||= ContentFromParams.content_from_params(params, fields)
    end
  end
end
