#server:  rm -f tmp/pids/server.pid && bundle exec rails s puma -p 3000 -b 0.0.0.0
server:  rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb
sidekiq: rm -f tmp/pids/sidekiq.pid && nohup bundle exec sidekiq
