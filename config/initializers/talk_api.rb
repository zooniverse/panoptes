Rails.application.reloader.to_prepare do
  TalkApiClient.load_configuration
end
