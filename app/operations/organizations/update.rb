require_relative '../../../lib/filters/organization_filter.rb'

module Organizations
  class Update < Operation
    include UrlLabels
    include ContentFromParams

    organization :organization_params
    string :id

    def execute
      Organization.transaction(requires_new: true) do
        content_update = HashWithIndifferentAccess.new
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

        organization.organization_contents.tap do |content|
          results = content_from_params(inputs[:organization_params], Api::V1::OrganizationsController::CONTENT_FIELDS) do |ps|
            ps["title"] = ps["display_name"]
          end
          content_update.merge! results
          content.assign_attributes(content_update)
        end

        if org_update[:listed] == true
          organization.listed_at = Time.zone.now
        else
          organization[:listed_at] = nil
        end
        organization.update!(org_update.symbolize_keys)
      end
    end

    private

    def organization
      @organization ||= Organization.find(id)
    end

    def language
      @language ||= organization_params[:primary_language] ? organization_params[:primary_language] : @organization.primary_language
    end
  end
end
