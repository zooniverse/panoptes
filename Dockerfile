FROM zooniverse/ruby:jruby-1.7.16.1

WORKDIR /rails_app

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/
ADD ./Jarfile /rails_app/
ADD ./Jarfile.lock /rails_app/

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y git && apt-get clean && \
    bundle install --without test development && \
    jbundle install --without test development

ADD ./ /rails_app

EXPOSE 80

ENTRYPOINT /rails_app/start.sh
