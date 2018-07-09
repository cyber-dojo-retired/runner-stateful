FROM  docker:latest
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - -
# install ruby+
# tar is needed to tar-pipe test coverage out of tmpfs.
# - - - - - - - - - - - - - - - -

RUN apk --update --no-cache add \
    bash \
    ruby-bundler \
    ruby-dev \
    tar

# - - - - - - - - - - - - - - - -
# install ruby gems
# - - - - - - - - - - - - - - - -

ARG            RUNNER_STATEFUL_HOME
COPY Gemfile ${RUNNER_STATEFUL_HOME}/
WORKDIR      ${RUNNER_STATEFUL_HOME}

RUN apk --update add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && bundle install \
  && gem clean \
  && apk del build-dependencies build-base \
  && rm -vrf /var/cache/apk/*

# - - - - - - - - - - - - - - - -
# setup client
# - - - - - - - - - - - - - - - -

COPY . ${RUNNER_STATEFUL_HOME}

CMD [ "./up.sh" ]
