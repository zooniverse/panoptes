Rails.application.config.to_prepare do
    DesignatorClient.load_configuration
end
