Honeybadger.configure do |config|
  config_file = begin
                  YAML.load(File.read(Rails.root.join("config/honeybadger.yml")))
                rescue Errno::ENOENT => e
                  {}
                end
  config.api_key = config_file.fetch(Rails.env, {}).symbolize_keys[:api_key]
  config.ignore.each.with_index do |_, index|
    config.ignore[index] = nil
  end
  config.ignore.compact!

  config.async do |notice|
    HoneybadgerWorker.perform_async(notice.to_json)
  end
end
