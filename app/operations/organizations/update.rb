module Organizations
  class Update < Operation
    include UrlLabels
    require_relative '../../../lib/filters/organization_filter.rb'

    organization :organization_params
    string :id

    def execute
      Organization.transaction do
        organization = Organization.find(id)
        content_update = {}
        org_update = organization_params.dup
        Api::V1::OrganizationsController::CONTENT_FIELDS.each do |field|
          if organization_params[field]
            content_update[field] = organization_params[field] if organization_params[field]
            org_update.delete(field)
          end
        end
        organization.update!(org_update.symbolize_keys)
        organization.organization_contents.find_or_initialize_by(language: organization_params[:primary_language]) do |content|
          content_update.merge! content_from_params(inputs, Api::V1::OrganizationsController::CONTENT_FIELDS)
          content.update! content_update.symbolize_keys
        end
        organization.save!
      end
    end
  end
end
