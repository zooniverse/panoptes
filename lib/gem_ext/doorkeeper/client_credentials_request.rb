# frozen_string_literal: true

require 'doorkeeper/oauth/client_credentials_request'

Doorkeeper::OAuth::ClientCredentialsRequest.class_eval do
  private

  def custom_token_attributes_with_data
    raw_params = if parameters.respond_to?(:to_unsafe_h)
                   parameters.to_unsafe_h
                 elsif parameters.respond_to?(:to_h)
                   parameters.to_h
                 else
                   parameters
                 end

    raw_params
      .with_indifferent_access
      .slice(*Doorkeeper.config.custom_access_token_attributes)
      .symbolize_keys
  end
end
