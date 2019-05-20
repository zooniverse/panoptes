def next?
  File.basename(__FILE__) == "Gemfile.next"
end
source 'https://rubygems.org'

gem 'active_interaction', '~> 3.6.2'
gem 'active_model_serializers', '0.10.0.rc2' # Event stream
gem 'active_record_union', '~> 1.3.0'
gem 'activerecord-import', '~> 1.0'
gem 'aws-sdk', '~> 2.10'
gem "cellect-client", '~> 3.0.2'
gem 'dalli-elasticache'
gem 'deep_cloneable', '~> 2.3.2'
gem 'devise', '~> 4.6'
gem 'doorkeeper', '~> 4.4'
gem 'doorkeeper-jwt', '~> 0.2.1'
gem 'httparty'
gem 'faraday', '~> 0.15'
gem 'faraday-http-cache', '~> 2.0'
gem 'faraday_middleware', '~> 0.13'
gem 'flipper', '~> 0.9.0'
gem 'flipper-active_record'
gem 'flipper-ui'
gem 'gelf'
gem 'graphiql-rails'
gem 'graphql'
gem 'honeybadger', '~> 4.1.0'
gem 'jquery-rails', '~> 4.3'
gem 'json-schema', '~> 2.8'
gem 'librato-metrics', '~> 2.1.2'
gem 'logstasher', '~> 1.3'
gem 'mime-types'
gem 'oauth2'
gem 'omniauth', '~> 1.9'
gem 'omniauth-facebook', '~> 5.0'
gem 'omniauth-google-oauth2'
gem 'p3p', '~> 2.0'
gem 'panoptes-client'
gem 'pg', '~> 0.21'
gem 'pg_search'
gem 'puma', '~> 3.12.1'
gem 'pundit', '~> 1.1.0'
gem 'rack-cors', '~> 0.4', require: 'rack/cors'
if next?
  gem 'rails', '~> 5.0.0'
  gem 'restpack_serializer', github: "zooniverse/restpack_serializer", branch: "rails5" # REST API
else
  gem 'rails', '~> 4.2.11'
  gem 'restpack_serializer', github: "zooniverse/restpack_serializer", branch: "rails5" # REST API
end
gem 'ranked-model', '~> 0.4.1'
gem 'schema_plus_pg_indexes', '~> 0.1'
gem 'scientist', '~> 1.2.0'
gem 'sdoc', '~> 1.0.0', group: :doc
gem 'semantic_logger', '~> 4.4.0'
gem 'sidekiq', '~> 5.2.5'
gem 'sidekiq-congestion', '~> 0.1.0'
gem 'sidekiq-unique-jobs'
gem 'sidetiq', '~> 0.7'
gem 'standby'
gem 'stringex', '~> 2.8'
gem 'therubyracer', '~> 0.12'
gem 'uglifier', '~> 4.1'
gem 'versionist', '~> 1.6'
gem 'zoo_stream', '~> 1.0.1'

group :production, :staging do
  gem 'newrelic_rpm'
end

group :development, :test do
  gem "factory_bot_rails"
  gem 'foreman'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'spring'
  gem 'ten_years_rails'
end

group :test do
  gem 'database_cleaner', '~> 1.7.0'
  gem 'guard-rspec', require: false
  gem 'hashdiff'
  gem 'mock_redis'
  gem 'rails-controller-testing' if next?
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
end
