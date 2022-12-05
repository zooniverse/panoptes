#!/bin/bash -ex

cd /rails_app

# cleanup the dump worker temp files
# that have not changed (had data added to them) in the last 6 hours
# use the mtime (default is atime)
# reason: handle the case where the exporter died mid export
#         e.g the disk filled up OR OOM error on container process
tmpreaper 6h --mtime /tmp/

mkdir -p tmp/pids/
rm -f tmp/pids/*.pid

exec bundle exec puma -C config/puma.rb
