module UrlLabels
  extend ActiveSupport::Concern

  def content_from_params(ps, content_fields)
    yield ps if block_given?
    content = ps.slice(*content_fields)
    content[:language] = ps[:primary_language]
    if ps.has_key? :urls
      urls, labels = extract_url_labels(ps[:urls])
      content[:url_labels] = labels
      ps[:urls] = urls
    end
    ps.except!(*content_fields)
    content.select { |k,v| !!v }
  end

  def extract_url_labels(urls)
    visitor = TasksVisitors::ExtractStrings.new
    visitor.visit(urls)
    [urls, visitor.collector]
  end
end
