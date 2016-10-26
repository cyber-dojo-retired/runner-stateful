FROM cyberdojo/runner_base
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ARG DOCKER_ENGINE_VERSION
RUN apk --update add curl \
  && curl -OL https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_ENGINE_VERSION}.tgz \
  && tar -xvzf docker-${DOCKER_ENGINE_VERSION}.tgz \
  && mv docker/* /usr/bin/ \
  && rmdir docker \
  && rm docker-${DOCKER_ENGINE_VERSION}.tgz \
  && apk del curl

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ARG APP_DIR
COPY . ${APP_DIR}

ARG PORT
ENV PORT=${PORT}
EXPOSE ${PORT}
ENTRYPOINT [ "foreman", "start", "-d", "/app" ]
