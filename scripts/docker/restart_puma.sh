#!/bin/bash
# simple script to hot restart puma, https://github.com/puma/puma#restart
# e.g. docker exec -it 'panoptes_container_name' bash -c "/rails_app/scripts/docker/restart_puma.sh"
pkill -F tmp/pids/server.pid -USR2
