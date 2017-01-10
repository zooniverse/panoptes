module Organizations
  class Create < Operation
    string :name
    string :display_name
    string :primary_language

    # Organization Contents Fields
    string :title
    string :description
    string :introduction, default: ''
    array :urls

    def execute
      Organization.transaction do
        organization = Organization.new owner: api_user.user, name: name, display_name: display_name, primary_language: primary_language
        param_hash = { title: title, description: description, introduction: introduction }
        param_hash.merge! content_from_params(inputs)
        # organization.organization_contents.build title: title, description: description, introduction: introduction, language: primary_language, urls: contenturls
        organization.organization_contents.build param_hash
        organization.save!
        organization
      end
    end

    def content_from_params(ps)
      content = ps.slice(Api::V1::OrganizationsController::CONTENT_FIELDS)
      content[:language] = ps[:primary_language]
      if ps.has_key? :urls
        urls, labels = extract_url_labels(ps[:urls])
        content[:url_labels] = labels
        ps[:urls] = urls
      end
      ps.except!(Api::V1::OrganizationsController::CONTENT_FIELDS)
      content.select { |k,v| !!v }
    end

    def extract_url_labels(urls)
      visitor = TasksVisitors::ExtractStrings.new
      visitor.visit(urls)
      [urls, visitor.collector]
    end
  end
end
