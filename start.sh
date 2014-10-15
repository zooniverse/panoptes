#!/bin/bash -ex

cd /rails_app


if [ "$RAILS_ENV" == "development" ]
then
    bundle install
    rake db:migrate
else
    ln -sf /rails_conf/* ./config/
fi

exec bundle exec rails s puma -p 80 $*
