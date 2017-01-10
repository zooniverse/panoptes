module Organizations
  class Organization < Operation
    def self.content_from_params(ps)
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

    def self.extract_url_labels(urls)
      visitor = TasksVisitors::ExtractStrings.new
      visitor.visit(urls)
      [urls, visitor.collector]
    end
  end
end
