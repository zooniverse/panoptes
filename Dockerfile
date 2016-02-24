FROM zooniverse/ruby:2.3

WORKDIR /rails_app

RUN apt-get update && \
    apt-get install --no-install-recommends -y git curl supervisor libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir config && curl "https://ip-ranges.amazonaws.com/ip-ranges.json" > config/aws_ips.json

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle install --without development test

ADD supervisord.conf /etc/supervisor/conf.d/panoptes.conf
ADD ./ /rails_app

RUN (cd /rails_app && git log --format="%H" -n 1 > commit_id.txt && rm -rf .git)

EXPOSE 81

ENTRYPOINT /rails_app/scripts/docker/start.sh
