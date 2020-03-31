Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
  config.request.filter_keys = %w[password password_confirmation RAW_POST_DATA]
end