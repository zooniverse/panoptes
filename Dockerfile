FROM zooniverse/ruby:jruby-1.7.16

WORKDIR /rails_app

ADD ./ /rails_app

RUN bundle install --without test development

EXPOSE 80

ENTRYPOINT /rails_app/start.sh
