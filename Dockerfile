FROM zooniverse/ruby:jruby-1.7.18

WORKDIR /rails_app

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install --no-install-recommends -y git && apt-get clean

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/
ADD ./Jarfile /rails_app/
ADD ./Jarfile.lock /rails_app/

RUN bundle install && jbundle install

ADD ./ /rails_app

EXPOSE 80

ENTRYPOINT /rails_app/scripts/docker/start.sh
