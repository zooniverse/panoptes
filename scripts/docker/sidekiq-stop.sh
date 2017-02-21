#!/bin/bash

scripts/docker/sidekiq-quiet.sh

for pidfile in tmp/pids/sidekiq_*.pid
do
    sidekiqctl stop $pidfile 86400
    until [ ! -f $pidfile ]
    do
        sleep 5
    done
done
