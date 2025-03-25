FROM ruby:2.7-slim

EXPOSE 4567
WORKDIR /usr/src/docs

RUN apt-get update && apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
    build-essential \
    nodejs \
    git \
    curl && \
    apt-get clean && rm -fr /var/lib/apt/lists/*

ADD ./Gemfile .
ADD ./Gemfile.lock .

RUN bundle install

ADD . .
