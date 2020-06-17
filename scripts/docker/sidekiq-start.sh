#!/bin/bash -ex

cd /rails_app
exec bundle exec sidekiq
