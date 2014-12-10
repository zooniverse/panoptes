#!/bin/bash -ex

cd /rails_app

if [ -d "/rails_conf/" ]
then
    ln -sf /rails_conf/* ./config/
fi

if [ "$RAILS_ENV" == "development" ]; then
  if [ -e /firstrun ]
  then
    if [ -d "/rails_app/.jbundler" ]
    then
        rm -rf /rails_app/.jbundler
    fi
    bundle install
    jbundle install
    rake db:migrate
    rm /firstrun
  else
    exec foreman start
  fi
else
  [ -z "$HOME" ] && export HOME=$(pwd)
  mkdir -p tmp/pids/
  rm -f tmp/pids/*.pid
  bundle exec sidekiq &
  exec bundle exec rails s puma -p 80 $*
fi
