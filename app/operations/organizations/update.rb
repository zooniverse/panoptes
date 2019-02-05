require_relative '../../../lib/filters/organization_filter.rb'

module Organizations
  class Update < Operation
    organization :organization_params
    string :id

    def execute
      Organization.transaction(requires_new: true) do
        org_update = organization_params.dup

        if org_update.key?(:tags)
          tags = Tags::BuildTags.run!(api_user: api_user, tag_array: org_update[:tags])
          organization.tags = tags unless tags.nil?
          org_update.delete(:tags)
        end

        if org_update.key?(:urls)
          urls, labels = UrlLabels.extract_url_labels(org_update[:urls])
          org_update[:url_labels] = labels
          org_update[:urls] = urls
        end

        if org_update[:listed] == true
          org_update[:listed_at] = Time.zone.now
        else
          org_update[:listed_at] = nil
        end

        organization.update!(org_update.symbolize_keys)

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
