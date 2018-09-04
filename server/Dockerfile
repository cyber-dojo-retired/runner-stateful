FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - -
# setup server
# - - - - - - - - - - - - - - - -

ARG RUNNER_STATEFUL_HOME
COPY . ${RUNNER_STATEFUL_HOME}

# - - - - - - - - - - - - - - - - -
# git commit sha image is built from
# - - - - - - - - - - - - - - - - -

ARG SHA
RUN echo ${SHA} > ${RUNNER_STATEFUL_HOME}/sha.txt

CMD [ "./up.sh" ]
