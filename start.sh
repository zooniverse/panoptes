#!/bin/bash -ex

cd /rails_app

ln -sf /rails_conf/* ./config/

bundle exec rake assets:precompile

exec rails s $*
