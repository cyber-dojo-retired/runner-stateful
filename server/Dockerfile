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

ARG app_dir
COPY . ${app_dir}
EXPOSE 4557
CMD [ "foreman", "start", "-d", "/app" ]
