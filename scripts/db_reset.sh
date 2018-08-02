#!/bin/bash

set -e
git stash -u
git checkout master
docker-compose run --rm --entrypoint="bundle exec rake db:reset" panoptes
git checkout -
git stash pop
docker-compose run --rm --entrypoint="bundle exec rake db:migrate" panoptes
docker-compose run --rm --entrypoint="bundle exec rake db:reset RAILS_ENV=test" panoptes

