app_path = File.expand_path(File.dirname(File.dirname(__FILE__)))

pidfile "#{app_path}/tmp/pids/server.pid"

dev_env = 'development'
rails_env = ENV['RAILS_ENV'] || dev_env
port = rails_env == dev_env ? 3000 : 81
environment rails_env
state_path "#{app_path}/tmp/pids/puma.state"

if rails_env == "production"
  stdout_redirect "#{app_path}/log/production.log", "#{app_path}/log/production_err.log", true
end

bind "tcp://0.0.0.0:#{port}"

# Code to run before doing a restart. This code should
# close log files, database connections, etc.
#
# This can be called multiple times to add code each time.
#
# on_restart do
#   puts 'On restart...'
# end

# === Cluster mode ===
workers 2

# Code to run when a worker boots to setup the process before booting
# the app.
#
# This can be called multiple times to add hooks.
#
on_worker_boot do
  ActiveRecord::Base.establish_connection

  # Enable New Relic RPM
  # https://github.com/puma/puma/issues/128#issuecomment-21050609
  require 'newrelic_rpm'
  NewRelic::Agent.manual_start
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
end

preload_app!

# Additional text to display in process listing
#
tag 'panoptes_api'
#
# If you do not specify a tag, Puma will infer it. If you do not want Puma
# to add a tag, use an empty string.

# Verifies that all workers have checked in to the master process within
# the given timeout. If not the worker process will be restarted. Default
# value is 60 seconds.
#
# worker_timeout 60

# Change the default worker timeout for booting
#
# If unspecified, this defaults to the value of worker_timeout.
#
# worker_boot_timeout 60
