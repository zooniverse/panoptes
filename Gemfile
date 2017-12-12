source 'https://rubygems.org'

gem 'rails', '~> 4.2.10'
gem 'postgres_ext', '~> 3.0.0'
gem 'active_record_union', '~> 1.2.0'
gem 'sdoc', '~> 0.4.2', group: :doc
gem 'doorkeeper', '~> 3.0'
gem 'doorkeeper-jwt', '~> 0.2.1'
gem 'devise', '~> 4.3'
gem 'versionist', '~> 1.6'
gem 'rack-cors', '~> 0.4', require: 'rack/cors'
gem 'restpack_serializer', github: "zooniverse/restpack_serializer", branch: "rails5" # REST API
gem 'active_model_serializers', '0.10.0.rc2' # Event stream
gem 'paper_trail', '~> 4.0'
# Needed because version 1.1.0 locks JWT at an older version than doorkeeper-jwt requires.
# Not a lot of commits between 1.1.0 and this ref. Remove this once the next version is released.
gem 'oauth2'
gem 'omniauth', '~> 1.7'
gem 'omniauth-facebook', '~> 4.0'
gem 'omniauth-google-oauth2'
gem 'puma', '~> 3.11.0'
gem 'logstasher', '~> 1.2'
gem 'semantic_logger', '~> 4.2.0'
gem 'gelf'
gem 'honeybadger', '~> 3.2'
gem 'jquery-rails', '~> 4.3'
gem 'uglifier', '~> 4.0'
gem 'sidekiq', '~> 5.0'
gem 'aws-sdk', '~> 2.10'
gem 'json-schema', '~> 2.8'
gem 'p3p', '~> 2.0'
gem 'stringex', '~> 2.8'
gem 'faraday', '~> 0.9'
gem 'faraday_middleware', '~> 0.12'
gem 'faraday-http-cache', '~> 2.0'
gem 'activerecord-import', '~> 0.21'
gem 'schema_plus_pg_indexes', '~> 0.1'
gem 'pg_search'
gem 'ranked-model', '~> 0.4.0'
gem 'sidekiq-congestion', '~> 0.1.0'
gem 'sidekiq-unique-jobs'
gem 'sidetiq', '~> 0.7'
gem "cellect-client", '~> 3.0.2'
gem 'active_interaction', '~> 3.6.1'
gem 'therubyracer', '~> 0.12'
gem 'pg', '~> 0.21'
gem 'zoo_stream', '~> 1.0.1'
gem 'librato-metrics', '~> 2.1.2'
gem 'scientist', '~> 1.1.0'
gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'
gem 'panoptes-client'
gem 'dalli-elasticache'
gem 'slavery'
gem 'graphql'
gem 'graphiql-rails'

group :production, :staging do
  gem 'newrelic_rpm'
end

group :development do
  gem 'fig_rake', '~> 0.9.3'
end

group :development, :test do
  gem 'foreman'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'spring'
end

group :test do
  gem 'database_cleaner', '~> 1.6.2'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'guard-rspec', require: false
  gem 'factory_girl_rails'
  gem 'spring-commands-rspec'
  gem 'mock_redis'
end
