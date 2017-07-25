# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

# require 'bootsnap/setup'
# vs https://github.com/Shopify/bootsnap/wiki/Bootlib::Require
require_relative '../lib/bootlib_require'
BootLib::Require.from_gem('bootsnap', 'bootsnap')

env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['ENV']
development_mode = ['', nil, 'development'].include?(env)

Bootsnap.setup(
  cache_dir:            'tmp/cache',      # Path to your cache
  development_mode:     development_mode, # Current working environment, e.g. RACK_ENV, RAILS_ENV, etc
  load_path_cache:      true,             # Optimize the LOAD_PATH with a cache
  autoload_paths_cache: true,             # Optimize ActiveSupport autoloads with cache
  disable_trace:        true,             # (Alpha) Set `RubyVM::InstructionSequence.compile_option = { trace_instruction: false }`
  compile_cache_iseq:   development_mode, # Compile Ruby code into ISeq cache, breaks coverage reporting.
  compile_cache_yaml:   development_mode  # Compile YAML into a cache
)

begin
  require "fig_rake/rails"
rescue LoadError => e
  p e if ENV['RAILS_ENV'] == 'development'
end
