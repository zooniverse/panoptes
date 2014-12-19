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
    # ensure the dev and test gems are installed
    # https://github.com/bundler/bundler/issues/2862
    bundle install --without nothing
    jbundle install --without nothing
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
