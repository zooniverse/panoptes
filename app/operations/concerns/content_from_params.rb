module ContentFromParams
  def content_from_params(ps, content_fields)
    yield ps if block_given?
    content = ps.slice(*content_fields)
    content[:language] = ps[:primary_language]
    if ps.key? :urls
      urls, labels = UrlLabels.extract_url_labels(ps[:urls])
      content[:url_labels] = labels
      ps[:urls] = urls
    end
    ps.except!(*content_fields)
    content.select { |k,v| !!v }
  end
end
