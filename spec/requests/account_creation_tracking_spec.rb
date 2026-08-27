# frozen_string_literal: true

require 'spec_helper'

describe 'account creation tracking', type: :request, with_cache_store: true do
  let(:ip_address) { '203.0.113.10' }
  let(:user_params) do
    [ :email, :password, :password_confirmation, :login, :display_name,
      :global_email_communication, :project_email_communication,
      :beta_email_communication, :project_id ]
  end
  let(:headers) do
    {
      'HTTP_ACCEPT' => 'application/json',
      'REMOTE_ADDR' => ip_address
    }
  end

  before do
    Rack::Attack.cache.store.clear
  end

  def account_creation_request
    post user_registration_path,
         params: { user: attributes_for(:user).slice(*user_params) },
         headers: headers
  end

  it 'tracks account creation by IP when the limit is exceeded' do
    tracked_requests = []
    subscription = ActiveSupport::Notifications.subscribe('track.rack_attack') do |_name, _start, _finish, _id, payload|
      tracked_requests << payload[:request]
    end

    6.times { account_creation_request }

    expect(tracked_requests.length).to eq(1)
    expect(tracked_requests.first.env['rack.attack.matched']).to eq('account_creation/ip')
    expect(tracked_requests.first.env['rack.attack.match_discriminator']).to eq(ip_address)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end

  it 'does not block account creation requests' do
    6.times do
      account_creation_request
      expect(response).to have_http_status(:created)
    end
  end
end
