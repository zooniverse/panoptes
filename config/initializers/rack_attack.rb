# frozen_string_literal: true

class Rack::Attack
  throttle('password_reset/email', limit: 5, period: 1.hour) do |req|
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
      params.dig('user', 'email').to_s.downcase.gsub(/\s+/, "").presence
    end
  end
end
