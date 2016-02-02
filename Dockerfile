FROM zooniverse/ruby:2.3.0

WORKDIR /rails_app

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install --no-install-recommends -y git curl supervisor libpq-dev && \
    apt-get clean

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle install --without development test

ADD supervisord.conf /etc/supervisor/conf.d/panoptes.conf
ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > commit_id.txt && rm -rf .git)

EXPOSE 81

ENTRYPOINT /rails_app/scripts/docker/start.sh
