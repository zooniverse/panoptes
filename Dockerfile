FROM ruby:2.5-stretch

WORKDIR /rails_app

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        git \
        curl \
        supervisor \
        libpq-dev \
        tmpreaper \
        libjemalloc1 \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

# set a default RAILS_ENV for the build scripts
# this is required for the `rake assets:precompile` script
# to write assets to target dir set in `config.assets.prefix`
ARG RAILS_ENV=production
ENV RAILS_ENV=$RAILS_ENV

RUN mkdir config && curl "https://ip-ranges.amazonaws.com/ip-ranges.json" > config/aws_ips.json

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1`
RUN bundle install --without development test

ADD supervisord.conf /etc/supervisor/conf.d/panoptes.conf
ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > commit_id.txt)
RUN (cd /rails_app && mkdir -p tmp/pids && rm -f tmp/pids/*.pid)
RUN (cd /rails_app && SECRET_KEY_BASE=1a bundle exec rake assets:precompile)

EXPOSE 81

CMD ["/rails_app/scripts/docker/start.sh"]
