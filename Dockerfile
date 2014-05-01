FROM ubuntu:12.04
MAINTAINER Edward Paget <ed@zooniverse.org>

ENV LANG en_US.UTF-8

# Install tools & libs to compile everything
RUN apt-get update 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libssl-dev libreadline-dev wget libc6-dev libssl-dev libreadline6-dev zlib1g-dev libyaml-dev libpq-dev
RUN apt-get clean

# Install ruby-build
RUN apt-get install -y git-core && apt-get clean
RUN git clone https://github.com/sstephenson/ruby-build.git && cd ruby-build && ./install.sh

# Install ruby 2.1.1
ENV CONFIGURE_OPTS --disable-install-rdoc
RUN ruby-build 2.1.1 /usr/local
RUN gem install bundler

WORKDIR /rails_app

ENV RAILS_ENV docker_dev
ADD Gemfile /rails_app/Gemfile
ADD Gemfile.lock /rails_app/Gemfile.lock
RUN bundle install

ADD ./ /rails_app

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

