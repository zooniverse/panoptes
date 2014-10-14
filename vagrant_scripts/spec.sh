#! /bin/bash

sudo docker inspect panoptes_spec
INSPECT_SPEC_STATUS=$?

sudo docker inspect test_postgres
INSPECT_PSQL_STATUS=$?

if [ $INSPECT_PSQL_STATUS = 1 ]; then
    sudo docker run -d -e DB="panoptes_test" \
        --name test_postgres -e PG_USER="panoptes" -e \
        PASS="panoptes" -v /opt/postgresql:/data \
        zooniverse/postgresql
fi

echo $INSPECT_SPEC_STATUS

if [ $INSPECT_SPEC_STATUS = 1 ]; then
    IMAGE="zooniverse/ruby:$(</home/vagrant/.ruby-version)"
    sudo docker run -i -t --name panoptes_spec \
        --link zookeeper:zookeeper --link test_postgres:postgres \
        -v /home/vagrant/panoptes/:/rails_app/ \
        -e "RAILS_ENV=test" $IMAGE \
        /bin/bash -c "cd /rails_app && bundle install && bundle exec spec"
else
    sudo docker start -a panoptes_spec
fi
