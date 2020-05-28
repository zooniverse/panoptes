#!/bin/bash -ex

cd /rails_app

if [ -d "/rails_conf/" ]
then
    ln -sf /rails_conf/* ./config/
fi

tmpreaper 7d /tmp/

mkdir -p tmp/pids/
rm -f tmp/pids/*.pid

if [ "$RAILS_ENV" == "development" ]; then
  exec bundle exec foreman start
else
  if [ ! -d public/api-assets ] || [ "$(ls -A public/api-assets)" == "" ]
  then
      bundle exec rake assets:precompile
  fi

  if [ -f "commit_id.txt" ]
  then
    cp commit_id.txt public/
  fi

  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi
