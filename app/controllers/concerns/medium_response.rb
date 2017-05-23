module MediumResponse
  def medium_response(medium)
    scope = Medium.where(id: medium)
    headers['ETag'] = gen_etag(scope)
    headers['Location'] = "#{request.protocol}#{request.host_with_port}/api#{medium.location}"
    headers['Last-Modified'] = medium.updated_at.httpdate
    json_api_render(:created, MediumSerializer.resource({}, scope))
  end
end
