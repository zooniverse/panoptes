#!/bin/bash -ex

cd /rails_app

tmpreaper 7d /tmp/

if [ "$RAILS_ENV" == "development" ]; then
  mkdir -p tmp/pids/
  rm -f tmp/pids/*.pid
  exec bundle exec foreman start
else
  if [ -f "commit_id.txt" ]
  then
    cp commit_id.txt public/
  fi

  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi
