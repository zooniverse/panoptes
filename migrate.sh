#!/bin/bash -ex

cd /rails_app

exec rake db:migrate
