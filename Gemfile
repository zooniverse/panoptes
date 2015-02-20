source 'https://rubygems.org'

gem 'jbundler', platform: :jruby
gem 'rails', '4.1.9'
gem 'postgres_ext', '2.4.0'
gem 'active_record_union', github: "edpaget/active_record_union", branch: "union-all"
gem 'sdoc', '~> 0.4.0',          group: :doc
gem 'doorkeeper', '~> 1.4.1'
gem 'devise'
gem 'versionist'
gem 'rack-cors', require: 'rack/cors'
gem 'restpack_serializer', github: "edpaget/restpack_serializer", branch: "dev"
gem 'paper_trail'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-gplus'
gem 'cellect-client', '0.1.2.pre.jruby'
gem 'puma'
gem 'logstasher'
gem 'honeybadger'
gem 'jquery-rails'
gem 'uglifier'
gem 'sidekiq'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'aws-sdk'
gem 'json-schema'
gem 'p3p'
gem 'newrelic_rpm'

platforms :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'therubyrhino'
  gem 'jruby-kafka', '1.0.0.beta'
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
  gem 'fig_rake', '~> 0.9.2'
end

group :development, :test do
  gem 'foreman'
  gem 'database_cleaner', '~> 1.2.0'
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-rails', '~> 3.0.0'
  gem 'guard-rspec', '~> 4.2.9', require: false
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'spring-commands-rspec', '~> 1.0.2'
  gem 'pry-rails', '~> 0.3.2'
end
