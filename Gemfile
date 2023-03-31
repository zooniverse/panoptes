# frozen_string_literal: true

def next?
  File.basename(__FILE__) == 'Gemfile.next'
end

source 'https://rubygems.org'

gem 'active_interaction'
gem 'active_model_serializers' # Event stream
gem 'active_record_extended'
gem 'activerecord-import', '~> 1.4'
gem 'aws-sdk', '~> 2.10'
gem 'azure-storage-blob'
gem 'dalli'
gem 'deep_cloneable', '~> 3.2.0'
gem 'devise', '~> 4.7'
gem 'doorkeeper', '~> 4.4'
gem 'doorkeeper-jwt', '~> 0.2.1'
gem 'faraday', '~> 1.10'
gem 'faraday-http-cache', '~> 2.4'
gem 'faraday_middleware', '~> 1.2'
gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'
gem 'graphiql-rails'
gem 'graphql'
gem 'honeybadger', '~> 5.2'
gem 'httparty'
gem 'jquery-rails', '~> 4.5'
gem 'json-schema', '~> 2.8'
gem 'librato-metrics', '~> 2.1.2'
gem 'lograge'
gem 'mime-types'
gem 'omniauth', '~> 1.9'
gem 'omniauth-facebook', '~> 5.0'
gem 'omniauth-google-oauth2'
gem 'p3p', '~> 2.0'
gem 'panoptes-client'
gem 'pg', '~> 1.4'
gem 'pg_search'
gem 'puma', '~> 6.1.1'
gem 'pundit', '~> 2.3.0'
gem 'rack-cors', '~> 1.0', require: 'rack/cors'
if next?
  gem 'rails', '~> 6.1'
else
  gem 'rails', '~> 6.1'
end
gem 'ranked-model', '~> 0.4.8'
gem 'restpack_serializer', git: 'https://github.com/zooniverse/restpack_serializer.git', branch: 'panoptes-api-version', ref: '5f1ef6c2b2'
gem 'scientist', '~> 1.6.3'
gem 'sidekiq', '< 7'
gem 'sidekiq-congestion', '~> 0.1.0'
gem 'sidekiq-cron'
gem 'sidekiq-unique-jobs'
gem 'standby'
gem 'stringex', '~> 2.8'
gem 'strong_migrations'
gem 'uglifier', '~> 4.2'
gem 'versionist', '~> 2.0'
gem 'zoo_stream', '~> 1.0.1'

group :production, :staging do
  gem 'newrelic_rpm'
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'mini_racer'
  gem 'pry'
  gem 'rubocop', '~> 0.91.0'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'spring', '~>2.1.1' # remove constraint once on or past rails 5.2
  gem 'sprockets', '~>3.7'
  gem 'ten_years_rails'
end

group :test do
  gem 'database_cleaner', '~> 1.99.0'
  gem 'guard-rspec', require: false
  gem 'listen', '~> 3.8'
  gem 'mock_redis'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
  gem 'webmock'
end
