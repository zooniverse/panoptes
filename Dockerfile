FROM zooniverse/ruby:jruby-1.7.18

WORKDIR /rails_app

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/
ADD ./Jarfile /rails_app/
ADD ./Jarfile.lock /rails_app/

ENV DEBIAN_FRONTEND noninteractive
ENV FIG_RAKE off
#ENV BUNDLE_WITHOUT test:development

RUN apt-get update && apt-get -y upgrade && \
    apt-get install --no-install-recommends -y git && apt-get clean && \
    bundle install && \
    jbundle install 

ADD ./ /rails_app

EXPOSE 80

ENTRYPOINT /rails_app/scripts/docker/start.sh
