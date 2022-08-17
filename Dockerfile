FROM ruby:2.6-slim-buster

WORKDIR /rails_app

RUN apt-get update && apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
        build-essential \
        # git is required for installing gems from git repos
        git \
        # libjemalloc1 (v3) provides big memory savings vs jemalloc v5+ (default on debian buster)
        libpq-dev \
        postgresql-client-11 \
        tmpreaper \
        && \
        apt-get clean


# set a default RAILS_ENV for the build scripts
# this is required for the `rake assets:precompile` script
# to write assets to target dir set in `config.assets.prefix`
ARG RAILS_ENV=production
ENV RAILS_ENV=$RAILS_ENV

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1`
RUN bundle install --without development test

ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > commit_id.txt)
RUN (cd /rails_app && mkdir -p tmp/pids && rm -f tmp/pids/*.pid)
RUN (cd /rails_app && SECRET_KEY_BASE=1a bundle exec rake assets:precompile)

EXPOSE 81

CMD ["/rails_app/scripts/docker/start.sh"]
