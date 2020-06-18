#!/bin/bash -ex

cd /rails_app

# cleanup the dump worker temp files
tmpreaper 7d /tmp/

mkdir -p tmp/pids/
rm -f tmp/pids/*.pid

if [ -f "commit_id.txt" ]
then
  cp commit_id.txt public/
fi

exec bundle exec puma -C config/puma.rb
