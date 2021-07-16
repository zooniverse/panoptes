# debian stretch has libjemalloc1 https://packages.debian.org/stretch/libjemalloc1
FROM ruby:2.5-slim-stretch

WORKDIR /rails_app

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get install --no-install-recommends -y \
        build-essential \
        # git is required for installing gems from git repos
        git \
        # libjemalloc1 (v3) provides big memory savings vs jemalloc v5+ (default on debian buster)
        libjemalloc1 \
        libpq-dev \
        tmpreaper \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

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
