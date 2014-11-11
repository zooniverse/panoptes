require 'spec_helper'

describe "wrap request parameters", type: :request do

  describe "json format" do
    it 'should not add a root node to the controller parameters' do
      get "/users/sign_up", nil, { "CONTENT_TYPE" => "application/json; charset=utf-8" }
      expect(request.params).not_to include(:registration)
    end
  end
end
