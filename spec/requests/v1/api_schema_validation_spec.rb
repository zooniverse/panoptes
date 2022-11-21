# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'api should only accept certain content types', type: :request do
  include APIRequestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, owner: user) }
  let(:headers) do
    { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1',
      'CONTENT_TYPE' => 'application/json' }
  end

  before do
    allow_any_instance_of(Api::ApiController).to receive(:doorkeeper_token).and_return(token(%w[public project], user.id))
  end

  context 'with valid create params' do
    before do
      post '/api/subject_sets',
           params: { subject_sets: { display_name: 'a name', links: { project: project.id.to_s } } }.to_json,
           headers: headers
    end

    it 'returns 200' do
      expect(response.status).to eq(201)
    end
  end

  context 'with invalid create params' do
    before do
      post '/api/subject_sets',
           params: { subject_sets: { extra: 'bad param', display_name: 'a name', links: { project: project.id.to_s } } }.to_json,
           headers: headers
    end

    it 'returns 422' do
      expect(response.status).to eq(422)
    end

    it 'includes an error message' do
      expect(JSON.parse(response.body)['errors'][0]).not_to be_empty
    end
  end
end
