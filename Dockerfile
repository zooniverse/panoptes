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

RUN mkdir config && curl "https://ip-ranges.amazonaws.com/ip-ranges.json" > config/aws_ips.json

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1`
RUN bundle install --without development test

ADD supervisord.conf /etc/supervisor/conf.d/panoptes.conf
ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > commit_id.txt)

EXPOSE 81

ENTRYPOINT /rails_app/scripts/docker/start.sh
