require 'spec_helper'

describe "translation api constraints", type: :request do
  include APIRequestHelpers
  let(:translation) { create(:project_translation) }
  let(:user) { translation.translated.owner }

  describe "POST request" do
    let(:url) { "/api/translations" }
    let(:payload) do
      { translations:
        {
          translated_type: "Project",
          language: "en-AU",
          strings: { title: "A great title", other: "strings" }
        }
      }
    end

    it "should allow create requests", :focus do
      as(user, scopes: %w(translation)) do |api_session|
        api_session.post(url, payload)
        expect(response.status).to eq(201)
      end
    end
  end

  # context "PUT requests" do
  #   let(:method) { :put }
  #   let(:body) do
  #     { "projects" => { "name" => "dave" } }
  #   end
  #
  #   it_behaves_like "precondition required"
  # end

  # context "HEAD requests" do
  #   let(:method) { :head }
  #
  #   it_behaves_like "returns etag"
  #   it_behaves_like "304s when not modified"
  # end
end
