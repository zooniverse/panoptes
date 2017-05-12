require 'active_support/concern'

module DefaultParams
  extend ActiveSupport::Concern

  included do
    let(:default_params) { {locale: I18n.locale} }

    def process_with_default_params(action, *args)
      if kwarg_request?(args)
        parameters = args[0][:params]
        args[0][:params] = default_params.merge(parameters || {})
      else
        parameters = args[1]
        args[1] = default_params.merge(parameters || {})
      end

      process_without_default_params(action, *args)
    end

    alias_method_chain :process, :default_params
  end
end

RSpec.configure do |config|
  config.include(DefaultParams, :type => :controller)
end
