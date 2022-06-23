# frozen_string_literal: true

module ExportMediumResponse
  def export_medium_response(medium)
    scope = Medium.where(id: medium.id)
    # this conversion of a AR::Relation scope to an array
    # should only ever be for one AR record and is safe to use for etag generation
    headers['ETag'] = gen_etag(scope.to_a)
    headers['Location'] = "#{request.protocol}#{request.host_with_port}/api#{medium.location}"
    headers['Last-Modified'] = medium.updated_at.httpdate
    json_api_render(:created, MediumSerializer.resource({}, scope))
  end
end
