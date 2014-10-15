Airbrake.configure do |config|
  begin
    config.api_key = if ENV['AIRBRAKE_API_KEY']
      ENV['AIRBRAKE_API_KEY']
    else
      yaml_data = YAML.load_file("#{Rails.root}/config/airbrake.yml")
      HashWithIndifferentAccess.new(yaml_data)[:api_key]
    end
  rescue Errno::ENOENT
  end
end
