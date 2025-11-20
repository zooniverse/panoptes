require 'spec_helper'

describe "password reset rate limiting", type: :request, with_cache_store: true do
  let(:json_headers) do
    {
      "HTTP_ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:html_headers) do
    {
      "HTTP_ACCEPT" => "text/html",
      "CONTENT_TYPE" => "application/x-www-form-urlencoded"
    }
  end

  let(:limit) { 5 }

  def password_reset_request(email)
    post user_password_path,
         params: { user: { email: email } }.to_json,
         headers: json_headers
  end

  def html_password_reset_request(email)
    post user_password_path,
         params: { user: { email: email } },
         headers: html_headers
  end

  describe "POST /users/password via JSON" do
    let(:user) { create(:user) }
    let(:email) { user.email }

    context "within rate limit" do
      it "allows the first request" do
        password_reset_request(email)
        expect(response).to have_http_status(:ok)
      end

      it "allows multiple requests up to the limit" do
        limit.times do |request_number|
          password_reset_request(email)
          expect(response).to have_http_status(:ok)
        end
      end

      it "allows requests from different email addresses" do
        users = create_list(:user, 3)

        users.each do |u|
          password_reset_request(u.email)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "exceeding rate limit" do
      it "blocks requests after exceeding the limit" do
        limit.times do |_|
          password_reset_request(email)
          expect(response).to have_http_status(:ok)
        end

        password_reset_request(email)
        expect(response).to have_http_status(:too_many_requests)
      end

      it "responds with 429 when throttled" do
        limit.times do
          password_reset_request(email)
        end

        password_reset_request(email)
        expect(response.status).to eq(429)
      end
    end

    context "rate limit per email address" do
      it "tracks the limit separately for each email" do
        user1 = create(:user)
        user2 = create(:user)

        limit.times do
          password_reset_request(user1.email)
          expect(response).to have_http_status(:ok)
        end

        password_reset_request(user2.email)
        expect(response).to have_http_status(:ok)

        password_reset_request(user1.email)
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "email normalization" do
      it "treats uppercase and lowercase emails as the same" do
        email_lower = user.email
        email_upper = user.email.upcase

        limit.times do
          password_reset_request(email_lower)
          expect(response).to have_http_status(:ok)
        end

        password_reset_request(email_upper)
        expect(response).to have_http_status(:too_many_requests)
      end

      it "treats emails with extra whitespace as the same" do
        email_with_space = " #{user.email} "

        limit.times do
          password_reset_request(user.email)
          expect(response).to have_http_status(:ok)
        end

        password_reset_request(email_with_space)
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "non-existent email addresses" do
      it "applies rate limiting even for non-existent emails" do
        email = "nonexistent@example.com"

        limit.times do
          password_reset_request(email)
          expect(response).to have_http_status(:ok)
        end

        password_reset_request(email)
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "nil or blank email" do
      it "does not apply rate limiting to nil email" do
        # nil email shouldn't trigger the throttle
        (limit+1).times do
          post user_password_path,
               params: { user: { email: nil } }.to_json,
               headers: json_headers
          # Will get 422 for invalid params, not 429
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      it "does not apply rate limiting to blank email" do
        # blank email shouldn't trigger the throttle
        (limit+1).times do
          post user_password_path,
               params: { user: { email: '' } }.to_json,
               headers: json_headers
          # Will get 422 for invalid params, not 429
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "other endpoint paths" do
      it "only applies rate limiting to /users/password POST requests" do
        # Don't throttle GET requests
        (limit+1).times do
          get user_password_path, headers: json_headers
          expect(response.status).not_to eq(429)
        end
      end

      it "doesn't throttle PUT requests to password endpoint" do
        # Ensure we're only throttling POST (create), not PUT (update)
        (limit+1).times do
          put user_password_path,
              params: { user: { password: "newpassword", password_confirmation: "newpassword", reset_password_token: "invalid" } }.to_json,
              headers: json_headers
          expect(response.status).not_to eq(429)
        end
      end
    end
  end

  describe "rate limit reset after expiration" do
    let(:user) { create(:user) }

    it "allows new requests after the cache expires" do
      limit.times do
        password_reset_request(user.email)
        expect(response).to have_http_status(:ok)
      end

      password_reset_request(user.email)
      expect(response).to have_http_status(:too_many_requests)

      # Manually clear the cache. Will normally expire after defined period.
      Rack::Attack.cache.store.clear

      password_reset_request(user.email)
      expect(response).to have_http_status(:ok)
    end
  end

  context "POST /users/password via HTML" do
    let(:user) { create(:user) }
    let(:email) { user.email }

    it "also applies rate limiting to HTML form submissions" do
      limit.times do
        html_password_reset_request(email)
      end

      html_password_reset_request(email)
      expect(response).to have_http_status(:too_many_requests)
    end

    context "shares the rate limit with JSON requests from the same email" do
      # Hit the limit with a mixed set of requests
      before do
        (limit/2 +1).times do
          password_reset_request(email)
        end

        (limit/2 +1).times do
          html_password_reset_request(email)
        end
      end

      it "throttles the next HTTP request when limit is reached" do
        html_password_reset_request(email)
        expect(response).to have_http_status(:too_many_requests)
      end

      it "throttles the next JSON request when limit is reached" do
        password_reset_request(email)
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
