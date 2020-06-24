#!/bin/bash
# https://github.com/puma/puma#restart
# simple script to phase restart the puma workers to avoid any downtime
# e.g. docker-compose exec panoptes scripts/docker/restart_puma.sh"
pkill -F tmp/pids/server.pid -USR2
