#!/bin/bash -ex

cd /rails_app

if [ -d "/rails_conf/" ]
then
    ln -sf /rails_conf/* ./config/
fi

if [ "$RAILS_ENV" == "development" ]; then
  if [ -e /firstrun ]; then
    rake db:migrate
    rm /firstrun
  fi
  exec foreman start
else
  mkdir -p tmp/pids/
  rm -f tmp/pids/*.pid
  bundle exec sidekiq &
  exec bundle exec rails s puma -p 80 $*
fi
