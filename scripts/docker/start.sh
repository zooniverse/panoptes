#!/bin/bash -ex

cd /rails_app

if [ -d "/rails_conf/" ]
then
    ln -sf /rails_conf/* ./config/
fi

mkdir -p tmp/pids/
rm -f tmp/pids/*.pid

if [ "$RAILS_ENV" == "development" ]; then
  exec foreman start
else
  USER_DATA=$(curl --fail http://169.254.169.254/latest/user-data || echo "")

  if [ "$USER_DATA" == "EMERGENCY_MODE" ]
  then
    git pull
  fi

  if [ ! -d public/assets ]
  then
      bundle exec rake assets:precompile
  fi

  if [ -f "commit_id.txt" ]
  then
    cp commit_id.txt public/
  fi

  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi
