require File.expand_path('../boot', __FILE__)

require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require 'flipper/middleware/memoizer'
require_relative 'cache_store'

Bundler.require(*Rails.groups)

module Panoptes
  class Application < Rails::Application
    config.eager_load_paths += Dir[Rails.root.join('app', 'models', '*/')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'workers', '*/')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'operations', '*/')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'serializers', '*/')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'formatters', '*/')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'policies', '*/')]

    config.eager_load_paths += Dir[Rails.root.join('lib', '**/')]

    config.action_dispatch.perform_deep_munge = false
    config.middleware.insert_before ActionDispatch::Cookies, "RejectPatchRequests"
    config.action_controller.action_on_unpermitted_parameters = :raise
    config.middleware.insert_before ActionDispatch::Cookies, "CatchApiJsonParseErrors"

    config.active_record.schema_format = :sql

    config.middleware.insert_before 0, Rack::Cors do
      Array.wrap(Panoptes.cors_config.allows).each do |allow_config|
        allow do
          origins allow_config[:origins]
          resource allow_config[:resource],
            headers: Panoptes.cors_config.headers,
            methods: Panoptes.cors_config.request_methods,
            expose: Panoptes.cors_config.expose,
            max_age: Panoptes.cors_config.max_age,
            credentials: allow_config[:credentials]
        end
      end
    end

    config.middleware.use Flipper::Middleware::SetupEnv, -> { Panoptes.flipper }
    config.middleware.use Flipper::Middleware::Memoizer

    if Panoptes::Cache.enabled?
      if (_rails4 = Gem::Version.new(Rails.version) < Gem::Version.new('5.0'))
        # use ENV MEMCACHE_SERVERS var to configure the servers
        # https://github.com/petergoldstein/dalli#usage-with-rails-3x-and-4x
        config.cache_store = :dalli_store, nil, Panoptes::Cache.options
      else
        # Rails 5 configuration of memcache and dalli
        # https://github.com/petergoldstein/dalli/wiki/Using-Dalli-with-Rails#cache-store
        config.cache_store = :mem_cache_store, Panoptes::Cache.servers, Panoptes::Cache.options
      end
    end
  end
end
