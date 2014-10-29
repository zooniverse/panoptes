source 'https://rubygems.org'

gem 'rails', '4.1.6'
gem 'postgres_ext'
gem 'sdoc', '~> 0.4.0',          group: :doc
gem 'doorkeeper', '~> 1.4.0'
gem 'devise'
gem 'versionist'
gem 'rack-cors', require: 'rack/cors'
gem 'protected_attributes', '~> 1.0.8'
gem 'restpack_serializer', '~> 0.5.4'
gem 'paper_trail'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-gplus'
gem 'cellect-client', '~> 0.0.7'
gem 'puma'
gem 'logstasher'
gem 'airbrake', '~> 4.1.0'
gem 'jquery-rails'
gem 'uglifier'
gem 'sidekiq'

platforms :jruby do
  gem 'jbundler'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'therubyrhino'
  gem 'jruby-kafka'
end

platforms :ruby do
  gem 'therubyracer'
  gem 'pg'
  gem 'poseidon'
end

group :development do
  gem 'spring'
  gem 'mysql2', platforms: :ruby
  gem 'activerecord-jdbcmysql-adapter', platforms: :jruby
end

group :development, :test do
  gem 'database_cleaner', '~> 1.2.0'
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-rails', '~> 3.0.0'
  gem 'guard-rspec', '~> 4.2.9', require: false
  gem 'factory_girl_rails', '~> 4.4.1'
  gem 'spring-commands-rspec', '~> 1.0.2'
  gem 'pry-rails', '~> 0.3.2'
end
