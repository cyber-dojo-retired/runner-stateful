FROM alpine:3.4
MAINTAINER Jon Jagger <jon@jaggersoft.com>

ARG app_dir

WORKDIR ${app_dir}/

COPY Gemfile ${app_dir}/

RUN export RACK_ENV='production'

# server/test/src/run.sh needs bash
# Gemfile: source 'https://rubygems.org'
RUN apk --update --no-cache add \
    openssl ca-certificates \
    ruby ruby-io-console bash ruby-dev ruby-bundler

# http://stackoverflow.com/questions/1381725
RUN echo 'gem: --no-document' > ~/.gemrc

RUN apk --update add --virtual build-dependencies build-base \
  && bundle install && gem clean \
  && apk del build-dependencies \
  && rm -vrf /var/cache/apk/*
