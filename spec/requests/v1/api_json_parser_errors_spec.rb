require "spec_helper"

RSpec.describe "handle malformed json", type: :request do
  it 'should return 400 Bad Request' do
    post "/api/classifications", 'this: "isn\'t json"', {
           "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
           "CONTENT_TYPE" => "application/json"
         }
    expect(response).to have_http_status(:bad_request)
  end
end
