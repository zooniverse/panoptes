FROM zooniverse/ruby:jruby-1.7.16

WORKDIR /rails_app

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN jbundle install --without test development

ADD ./ /rails_app

EXPOSE 80

ENTRYPOINT /rails_app/start.sh
