FROM cyberdojo/runner_base
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ARG  DOCKER_VERSION
RUN apk --update add curl \
  && curl -OL https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz \
  && tar -xvzf docker-${DOCKER_VERSION}.tgz \
  && mv docker/* /usr/bin/ \
  && rmdir docker \
  && rm docker-${DOCKER_VERSION}.tgz \
  && apk del curl

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# -D=no password, -H=no home directory
RUN adduser -D -H -u 19661 cyber-dojo

ARG  DOCKER_BINARY=/usr/bin/docker
ARG  NEEDS_DOCKER_SUDO=cyber-dojo
ARG  GETS_DOCKER_SUDO=docker-runner
ARG  SUDO_FILE=/etc/sudoers.d/${GETS_DOCKER_SUDO}
# -D=no password, -H=no home directory
RUN  adduser -D -H ${GETS_DOCKER_SUDO}
# there is no sudo command in Alpine
RUN  apk --update add sudo
# cyber-dojo, on all hosts, can sudo -u docker-runner, without a password
RUN  echo "${NEEDS_DOCKER_SUDO} ALL=(${GETS_DOCKER_SUDO}) NOPASSWD: ALL" >  ${SUDO_FILE}
# docker-runner, on all hosts, without a password, can sudo /usr/bin/docker
RUN  echo "${GETS_DOCKER_SUDO}  ALL=NOPASSWD: ${DOCKER_BINARY} *"       >>  ${SUDO_FILE}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ARG app_dir
COPY . ${app_dir}
EXPOSE 4557
