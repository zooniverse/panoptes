module Organizations
  class Update < Organization
    integer :id
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
        organization = Organization.find(id)
        organization.update!(name: name, display_name: display_name, primary_language: primary_language)
        organization.organization_contents.find_or_initialize_by(language: primary_language) do |content|
          param_hash = { title: title, description: description, introduction: introduction }
          param_hash.merge! content_from_params(inputs)
          content.update! param_hash
          # content.update! title: title, description: description, introduction: introduction, url_labels: url_labels
        end
        organization.save!
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
