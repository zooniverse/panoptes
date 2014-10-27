#!/bin/bash -ex

cd /rails_app

if [ -d "/rails_app/.jbundler" ]
then
    rm -rf /rails_app/.jbundler
fi

if [ -d "/rails_conf/" ]
then
    ln -sf /rails_conf/* ./config/
fi

if [ "$RAILS_ENV" == "development" ]
then
    rake db:migrate
fi

exec bundle exec rails s puma -p 80 $*
