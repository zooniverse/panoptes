# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
begin
  require "fig_rake/rails"
rescue LoadError => e
  p e if ENV['RAILS_ENV'] == 'development'
end
