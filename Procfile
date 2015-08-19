server:  rm -f tmp/pids/server.pid && if [ ! -d public/assets ]; then bundle exec rake assets:precompile; fi && bundle exec rails s puma -p 80 -b 0.0.0.0
sidekiq: rm -f tmp/pids/sidekiq.pid && nohup bundle exec sidekiq
