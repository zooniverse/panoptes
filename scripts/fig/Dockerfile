FROM zooniverse/ruby:jruby-1.7.16.1

VOLUME ./:/rails_app

WORKDIR /rails_app

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/
ADD ./Jarfile /rails_app/
ADD ./Jarfile.lock /rails_app/

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y git && apt-get clean

RUN bundle install && jbundle install

RUN touch /firstrun

ADD ./ /rails_app

EXPOSE 80

ENTRYPOINT /rails_app/start.sh
