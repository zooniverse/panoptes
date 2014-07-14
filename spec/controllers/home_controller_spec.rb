require 'spec_helper'

describe HomeController, type: :controller do

  describe "GET 'index'" do

    before(:each) do
      get 'index'
    end

    it "returns success" do
      expect(response).to be_success
    end

    it "returns the expected json header" do
      expected_header_regex = /^application\/vnd.api\+json; version=\d; charset=utf-8$/
      content_header = response.headers["Content-Type"]
      expect(content_header.match(expected_header_regex)).to be_truthy
    end

    it "should respond with a json response for the root" do
      get :index
      json_response = JSON.parse(response.body)
      expect(json_response).to eq({})
    end
  end
end
