FROM ruby:2.5.1

EXPOSE 4567
WORKDIR /src

RUN apt-get update && \
    apt-get install -y nodejs git curl && \
    apt-get clean && rm -fr /var/lib/apt/lists/*

RUN echo "Host *" >> /etc/ssh/ssh_config &&\
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD ./docs/Gemfile /src/docs/Gemfile
ADD ./docs/Gemfile.lock /src/docs/Gemfile.lock
RUN cd /src/docs && bundle install

ADD . /src
