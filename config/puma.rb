# For more information: https://github.com/puma/puma/blob/master/examples/config.rb
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

# === Cluster mode ===
case rails_env
when "production"
  workers 2
  threads 0,8
when "staging"
  workers 2
  threads 0,4
end

# Additional text to display in process listing
tag 'panoptes_api'
