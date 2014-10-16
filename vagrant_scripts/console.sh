#! /bin/bash

docker inspect panoptes_console > /dev/null

if [ $? != 0 ]; then
    IMAGE="zooniverse/ruby:$(</home/vagrant/.ruby-version)"
    docker run -i -t --name panoptes_console \
        --link zookeeper:zookeeper --link postgres:postgres \
        -v /home/vagrant/panoptes/:/rails_app/ \
        -e "RAILS_ENV=development" $IMAGE \
        /bin/bash -c "cd /rails_app && bundle install && bundle exec rails c"
else
    docker start -a -i panoptes_console
fi
