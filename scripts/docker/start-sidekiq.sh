#!/bin/bash -ex

cd /rails_app
# defaults are loaded via the yaml at default location, config/sidekiq.yml
# SIDEKIQ_ARGS are used to override the values in the YAML, e.g. -q special_queue
CLI_ARGS=${SIDEKIQ_ARGS:-''}
exec bundle exec sidekiq $CLI_ARGS
