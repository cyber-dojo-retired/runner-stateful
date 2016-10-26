FROM alpine:3.4
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# server/test/src/run.sh needs bash
# Gemfile: source 'https://rubygems.org'
RUN apk --update --no-cache add \
    openssl ca-certificates \
    ruby ruby-io-console bash ruby-dev ruby-bundler

# http://stackoverflow.com/questions/1381725
RUN echo 'gem: --no-document' > ~/.gemrc

ARG APP_DIR
COPY Gemfile ${app_dir}/
WORKDIR ${app_dir}/

RUN apk --update add --virtual build-dependencies build-base \
  && bundle install && gem clean \
  && apk del build-dependencies \
  && rm -vrf /var/cache/apk/*

ENV RACK_ENV='production'
