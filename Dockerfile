FROM ruby:3.1-bullseye


WORKDIR /rails_app

RUN apt-get update && apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
        build-essential \
        # git is required for installing gems from git repos
        git \
        # install jemalloc (v5) for memory savings
        libjemalloc2 \
        libpq-dev \
        nodejs \
        tmpreaper \
        && \
        apt-get clean

# configure jemalloc v5 with v3 behaviours (trade ram usage over performance)
# https://twitter.com/nateberkopec/status/1442894624935137288
# https://github.com/code-dot-org/code-dot-org/blob/5c8b24674d1c2f7e51e85dd32124e113dc423d84/cookbooks/cdo-jemalloc/attributes/default.rb#L10
ENV MALLOC_CONF="narenas:2,background_thread:true,thp:never,dirty_decay_ms:1000,muzzy_decay_ms:0"
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# set a default RAILS_ENV for the build scripts
# this is required for the `rake assets:precompile` script
# to write assets to target dir set in `config.assets.prefix`
ARG RAILS_ENV=production
ENV RAILS_ENV=$RAILS_ENV

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1`

# run gem update system so installation of mini_racer does not fail
# See troubleshooting for mini_racer and supported ruby versions: https://github.com/rubyjs/mini_racer?tab=readme-ov-file#supported-ruby-versions--troubleshooting
# pinning gem update to 3.4.22 since anything higher requires updating Ruby version to 3+
RUN gem i "rubygems-update:~>3.4.22" --no-document && update_rubygems
RUN bundle install --without development test

ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > public/commit_id.txt)
RUN (cd /rails_app && mkdir -p tmp/pids && rm -f tmp/pids/*.pid)
RUN (cd /rails_app && SECRET_KEY_BASE=1a bundle exec rake assets:precompile)

EXPOSE 81

CMD ["/rails_app/scripts/docker/start.sh"]