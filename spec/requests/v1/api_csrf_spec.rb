# frozen_string_literal: true

require 'spec_helper'

describe 'api should not require csrf protection', type: :request do
  before do
    ActionController::Base.allow_forgery_protection = true
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'returns 200 when making a request without csrf' do
    user = create(:user)

    token = create(:access_token, resource_owner_id: user.id)
    allow(token).to receive(:accessible?).and_return(true)
    allow(token).to receive(:scopes)
      .and_return(Doorkeeper::OAuth::Scopes.from_array(%w[project public]))

    allow_any_instance_of(Api::V1::ProjectsController).to receive(:doorkeeper_token)
      .and_return(token)

    post '/api/projects', params: { projects: { display_name: 'New Hotness!',
                                                description: 'Your shits busted',
                                                primary_language: 'en',
                                                private: false } }.to_json,
                          headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1',
                                     'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(response.status).to eq(201)
  end
end
