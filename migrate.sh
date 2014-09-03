#!/bin/bash -ex

cd /rails_app

ln -sf /rails_conf/* ./config/

exec rake db:migrate RAILS_ENV="production"
