# frozen_string_literal: true

module Rack
  class Attack
    throttle('password_reset/email', limit: 1, period: 1.hour) do |req|
      if req.path.start_with?('/users/password') && req.post?
        # JSON request params must be manually parsed
        if req.env['CONTENT_TYPE'] == 'application/json'
          params = JSON.parse(req.body.read)
          # Body is an StringIO and needs to be read again downstream, so rewind
          req.body.rewind
        else
          # Otherwise, use the normal params hash
          params = req.params
        end
        params.dig('user', 'email').to_s.downcase.gsub(/\s+/, '').presence
      end
    end

    track('account_creation/ip', limit: 5, period: 1.day) do |req|
      req.ip if req.path == '/users' && req.post?
    end

    ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, payload|
      request = payload[:request]
      match_type = request.env['rack.attack.match_type']

      if %i[throttle track].include?(match_type)
        rate_limit_name = request.env['rack.attack.matched']
        match_data = request.env['rack.attack.match_data'] || {}

        Honeybadger.notify(
          "Rack::Attack Rate Limit Triggered: #{rate_limit_name}",
          error_class: 'RateLimitExceeded',
          context: {
            throttle: rate_limit_name,
            match_type: match_type,
            ip: request.ip,
            path: request.path,
            method: request.request_method,
            period: match_data[:period],
            limit: match_data[:limit],
            count: match_data[:count]
          }
        )
      end
    end
  end
end
