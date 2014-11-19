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
    foreman start
  fi
else
  exec bundle exec rails s puma -p 80 $*
fi
