# frozen_string_literal: true

require 'spec_helper'

describe 'kaminari zero page requests', type: :request do
  let(:user) { create(:user) }
  let(:api_default_params) do
    {
      'HTTP_ACCEPT' => 'application/vnd.api+json; version=1'
    }
  end

  before do
    get "/api/users/#{user.id}", { page_size: 0 }, api_default_params
  end

  it 'returns the 422 error code' do
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'returns a useful response error message' do
    error_message = "Current page was incalculable. Perhaps you supplied 'page_size: 0' as a param?"
    expect(response.body).to eq(json_error_message(error_message))
  end
end
