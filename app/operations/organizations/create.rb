module Organizations
  class Create < Operation
    # trust the controller level json schema validations
    # https://github.com/AaronLasseigne/active_interaction/tree/fdc00a041e939ef48948baa2f7fd1ce2e4d66982#hash
    hash :schema_create_params, strip: false

    def execute
      Organization.transaction(requires_new: true) do
        organization = Organization.new(create_params)

        if schema_create_params[:tags]
          organization.tags = Tags::BuildTags.run!(
            api_user: api_user,
            tag_array: tags
          )
        end

        organization.save!
        organization
      end
    end

    private

    def create_params
      schema_create_params.merge(
        {
          owner: api_user.user,
          urls: urls_without_labels,
          url_labels: url_labels,
        }
      )
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
      @extract_url_labels ||= UrlLabels.extract_url_labels(schema_create_params[:urls])
    end
  end
end
