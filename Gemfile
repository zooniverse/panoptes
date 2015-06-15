source 'https://rubygems.org'

gem 'jbundler', platform: :jruby
gem 'rails', '4.2.1'
gem 'postgres_ext', '~> 2.4.0'
gem 'active_record_union', github: "edpaget/active_record_union", branch: "union-all"
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'doorkeeper', '~> 1.4.1'
gem 'devise'
gem 'versionist'
gem 'rack-cors', require: 'rack/cors'
gem 'restpack_serializer', github: "edpaget/restpack_serializer", branch: "dev"
gem 'paper_trail'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-gplus'
gem 'puma'
gem 'logstasher'
gem 'honeybadger'
gem 'jquery-rails'
gem 'uglifier'
gem 'sidekiq'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'aws-sdk-v1'
gem 'json-schema'
gem 'p3p'
gem 'newrelic_rpm'
gem 'firebase_token_generator'
gem 'stringex'
gem 'faraday'
gem 'faraday_middleware'
gem 'faraday-http-cache'
gem "activerecord-import"

platforms :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'therubyrhino'
  gem 'jruby-kafka', '1.0.0.beta'
end

platforms :ruby do
  gem 'therubyracer'
  gem 'pg'
  gem 'poseidon'
  gem 'mysql2'
end

group :development do
  gem 'spring'
  gem 'fig_rake', '~> 0.9.3'
  gem 'sqlite3', platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
end

group :development, :test do
  gem 'foreman'
  gem 'database_cleaner', '~> 1.2.0'
  gem 'rspec', '~> 3.3.0'
  gem 'rspec-rails', '~> 3.3.0'
  gem 'guard-rspec', '~> 4.2.9', require: false
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'spring-commands-rspec', '~> 1.0.2'
  gem 'pry-rails', '~> 0.3.2'
end
