FROM ruby:2.5.1

EXPOSE 4567
WORKDIR /usr/src/docs

RUN apt-get update && \
    apt-get install -y nodejs git curl && \
    apt-get clean && rm -fr /var/lib/apt/lists/*

RUN echo "Host *" >> /etc/ssh/ssh_config &&\
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD ./Gemfile /usr/src/docs
ADD ./Gemfile.lock /usr/src/docs
RUN bundle install

ADD . /usr/src/docs