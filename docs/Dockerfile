FROM ruby:2.6

EXPOSE 4567
WORKDIR /usr/src/docs

RUN apt-get update && \
    apt-get install -y nodejs git curl && \
    apt-get clean && rm -fr /var/lib/apt/lists/*

ADD ./Gemfile .
ADD ./Gemfile.lock .
RUN bundle install

ADD . .
