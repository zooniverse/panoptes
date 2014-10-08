#!/bin/bash -ex

cd /rails_app

ln -sf /rails_conf/* ./config/

exec bundle exec rails s puma -p 80 $*
