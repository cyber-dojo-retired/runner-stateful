FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - -
# setup client
# - - - - - - - - - - - - - - - -

ARG RUNNER_STATEFUL_HOME
COPY . ${RUNNER_STATEFUL_HOME}

CMD [ "./up.sh" ]
