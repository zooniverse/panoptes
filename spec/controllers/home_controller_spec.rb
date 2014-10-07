require 'spec_helper'

describe HomeController, type: :controller do

  describe "GET 'index'" do

    context "with all media types" do

      before(:each) do
        request.env["HTTP_ACCEPT"] = "*/*"
        get 'index'
      end

      it "should be successful" do
        expect(response).to be_success
      end

      it "should default to html" do
        expect(response.content_type).to eq("text/html")
      end
    end

    context "as json" do
      before(:each) do
        get 'index', format: :json
      end

      it "returns success" do
        expect(response).to be_success
      end

      it "returns the expected json header" do
        expect(response.content_type).to eq("application/json")
      end

      it "should respond with a json response for the root" do
        expect(json_response).to eq({})
      end
    end
  end
end
