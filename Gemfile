source 'https://rubygems.org'

gem 'rails', '~> 4.2.5'
gem 'postgres_ext', '~> 2.4.0'
gem 'active_record_union', '~> 1.1.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'doorkeeper', '~> 3.0'
gem 'devise', '~> 3.0'
gem 'versionist', '~> 1.0'
gem 'rack-cors', '~> 0.3', require: 'rack/cors'
gem 'restpack_serializer', github: "edpaget/restpack_serializer", branch: "dev" # REST API
gem 'active_model_serializers', '0.10.0.rc2' # Event stream
gem 'paper_trail', '~> 3.0'
gem 'omniauth', '~> 1.0'
gem 'omniauth-facebook', '~> 3.0'
gem 'omniauth-gplus', '~> 2.0'
gem 'puma', '~> 3.1.0'
gem 'logstasher', '~> 0.6'
gem 'honeybadger', '~> 2.0'
gem 'jquery-rails', '~> 4.0'
gem 'uglifier', '~> 2.0'
gem 'sidekiq', '~> 4.0'
gem 'sinatra', '>= 1.3.0', require: nil
gem 'aws-sdk-v1', '~> 1.0'
gem 'json-schema', '~> 2.0'
gem 'p3p', '~> 1.0'
gem 'stringex', '~> 2.0'
gem 'faraday', '~> 0.9'
gem 'faraday_middleware', '~> 0.9'
gem 'faraday-http-cache', '~> 1.0'
gem 'activerecord-import', '~> 0.8'
gem 'schema_plus_pg_indexes', '~> 0.1'
gem 'pg_search'
gem 'ranked-model', '~> 0.4.0'
gem 'sidekiq-congestion', '~> 0.1.0'
gem 'sidetiq', '~> 0.7'
gem "cellect-client", '~> 2.0.1'
gem 'active_interaction', '~> 3.0.1'
gem 'therubyracer', '~> 0.12'
gem 'pg', '~> 0.18'
gem 'zoo_stream', '~> 1.0.1'

group :production do
  gem 'newrelic_rpm', '~> 3.0', require: false
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
  gem 'database_cleaner', '~> 1.3.0'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'guard-rspec', require: false
  gem 'factory_girl_rails'
  gem 'spring-commands-rspec'
end
