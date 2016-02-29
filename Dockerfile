FROM ruby:2.3-alpine

WORKDIR /rails_app

RUN apk add --no-cache git curl supervisor libxml2 libxslt libpq nodejs

RUN mkdir config && curl "https://ip-ranges.amazonaws.com/ip-ranges.json" > config/aws_ips.json

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN apk add --no-cache --virtual bundle-build \
        libxml2-dev libxslt-dev postgresql-dev build-base && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle config build.therubyracer --use-system-libraries && \
    bundle install --without development test && \
    apk del bundle-build

ADD supervisord.conf /etc/supervisor.d/panoptes.ini
ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > commit_id.txt && rm -rf .git)

EXPOSE 81

ENTRYPOINT /rails_app/scripts/docker/start.sh
