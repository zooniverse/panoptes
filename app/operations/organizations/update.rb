require_relative '../../../lib/filters/organization_filter.rb'

module Organizations
  class Update < Operation
    include UrlLabels
    include ContentFromParams

    organization :organization_params
    string :id

    set_callback :execute, :around, lambda { |_interaction, block|
      updated_organization = block.call
      TranslationSyncWorker.perform_async(
        Organization.name,
        updated_organization.id,
        updated_organization.primary_language
      )
      updated_organization
    }

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

        organization.update!(org_update.symbolize_keys)
        organization.organization_contents.find_or_initialize_by(language: language).tap do |content|
          results = content_from_params(inputs[:organization_params], Api::V1::OrganizationsController::CONTENT_FIELDS) do |ps|
            ps["title"] = ps["display_name"]
          end
          content_update.merge! results
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
  end
end
