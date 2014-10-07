#!/bin/bash -ex

cd /rails_app

ln -sf /rails_conf/* ./config/

exec rails s -p80 $*
