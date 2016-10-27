FROM cyberdojo/runner_base
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. install tini (for pid 1 zombie reaping)
# https://github.com/krallin/tini
# https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/

USER root
RUN apk add --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ tini
ENTRYPOINT ["/sbin/tini", "--"]

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. install docker-client

ARG DOCKER_ENGINE_VERSION
RUN apk --update add curl \
  && curl -OL https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_ENGINE_VERSION}.tgz \
  && tar -xvzf docker-${DOCKER_ENGINE_VERSION}.tgz \
  && mv docker/* /usr/bin/ \
  && rmdir docker \
  && rm docker-${DOCKER_ENGINE_VERSION}.tgz \
  && apk del curl

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. install app

ARG APP_DIR
COPY . ${APP_DIR}
WORKDIR ${APP_DIR}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 4. run

ARG PORT
ENV PORT=${PORT}
EXPOSE ${PORT}
CMD [ "foreman", "start" ]
