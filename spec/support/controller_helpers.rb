module APIResponseHelpers
  def json_response
    @json ||= JSON.parse(response.body)
  end

  def json_error_message(error_message)
    { errors: [ message: error_message ] }.to_json
  end

  def created_instance(instance_type)
    json_response[instance_type][0]
  end

  def created_instance_id(instance_type)
    created_instance(instance_type)["id"]
  end

  def created_instance_ids(instance_type)
    json_response[instance_type].collect{ |h| h['id'] }
  end

  def formated_string_ids(resources)
    resources.map { |r| r.id.to_s }
  end
end
