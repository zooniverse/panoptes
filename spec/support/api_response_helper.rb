module APIResponseHelpers

  def json_error_message(error_message)
    { errors: [ message: error_message ] }.to_json
  end
end
