require 'spec_helper'

describe "translation api custom route constraints", type: :request do
  include APIRequestHelpers
  let(:translation) { create(:project_translation) }
  let(:user) { translation.translated.owner }
  let(:query_params) do
    "translated_type=#{translation.translated_type}&translated_id=#{translation.translated_id}"
  end

  describe "POST request" do
    let(:url) { "/api/translations?#{query_params}" }
    let(:payload) do
      { translations:
        {
          language: "en-AU",
          strings: { title: "A great title", other: "strings" }
        }
      }
    end

    it "should allow create requests" do
      as(user, scopes: %w(translation)) do |api_session|
        api_session.post(url, payload)
        expect(response.status).to eq(201)
      end
    end
  end

  describe "PUT request" do
    let(:url) { "/api/translations/#{translation.id}?#{query_params}" }
    let(:payload) do
      { translations:
        {
          strings: { title: "A better title", other: "more of the strings" }
        }
      }
    end

    before do
      create(:project) # ensure the etag resource id's do not match
    end

    it "should allow update requests" do
      as(user, scopes: %w(translation)) do |api_session|
        api_session.put(url, payload)
        expect(response.status).to eq(200)
      end
    end
  end
end
