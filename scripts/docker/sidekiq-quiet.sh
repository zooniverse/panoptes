#!/bin/bash

for pidfile in tmp/pids/sidekiq_*.pid
do
    sidekiqctl quiet $pidfile
done
