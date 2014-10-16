#! /bin/bash

docker inspect panoptes_spec > /dev/null
INSPECT_SPEC_STATUS=$?

docker inspect test_postgres > /dev/null
INSPECT_PSQL_STATUS=$?

if [ $INSPECT_PSQL_STATUS != 0 ]; then
    docker run -d --name test_postgres \
        -e DB="panoptes_test" -e PG_USER="panoptes" \
        -e PASS="panoptes" -v /opt/postgresql:/data \
        zooniverse/postgresql

else
    docker start test_postgres
fi

if [ $INSPECT_SPEC_STATUS != 0 ]; then
    IMAGE="zooniverse/ruby:$(</home/vagrant/.ruby-version)"
    docker run -t --name panoptes_spec \
        --link zookeeper:zookeeper --link test_postgres:test_postgres \
        -v /home/vagrant/panoptes/:/rails_app/ \
        -e "RAILS_ENV=test" $IMAGE \
        /bin/bash -c "cd /rails_app && bundle install && rake db:schema:load && bundle exec rspec"
    docker stop test_postgres
else
    docker start -a panoptes_spec
fi
