#!/bin/bash -ex

cd /rails_app

ln -sf /rails_conf/* ./config/

if [ -z "$RAILS_ENV" ]
then
    export RAILS_ENV="production"
fi

exec rake db:migrate
