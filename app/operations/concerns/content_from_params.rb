module ContentFromParams
  def self.content_from_params(params, content_fields)
    content_params = params.slice(*content_fields)
    content_params[:language] = params[:primary_language]

    if params.key? :urls
      urls, labels = UrlLabels.extract_url_labels(params[:urls])
      content_params[:url_labels] = labels
      params[:urls] = urls
    end

    content_params.select { |k,v| !!v }
  end
end
