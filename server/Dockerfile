FROM cyberdojo/foreman
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# install docker-client
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. install docker-client
# Launching a docker app (that itself uses docker) is
# different on different host OS's... eg
#
# OSX 10.10 (Yosemite)
# --------------------
# The Docker-Quickstart-Terminal uses docker-machine to forward
# docker commands to a boot2docker VM called default.
# In this VM the docker binary lives at /usr/local/bin/
#
#    -v /usr/local/bin/docker:/usr/local/bin/docker
#
# Ubuntu 14.04 (Trusty)
# ---------------------
# The docker binary lives at /usr/bin and has a dependency on apparmor 1.1
#
#    -v /usr/bin/docker:/usr/bin/docker
#    -v /usr/lib/x86_64-linux-gnu/libapparmor.so.1.1.0 ...
#
# Debian 8 (Jessie)
# -----------------
# The docker binary lives at /usr/bin and has a dependency to apparmor 1.2
#
#    -v /usr/bin/docker:/usr/bin/docker
#    -v /usr/lib/x86_64-linux-gnu/libapparmor.so.1.2.0 ...
#
# I originally used docker-compose extension files specific to each OS.
# I now install the docker client _inside_ the image.
# This means there is no host<-container uid dependency.
# But there is a host<-container docker version dependency.
#
# docker 1.11.0+ now relies on four binaries
# See https://github.com/docker/docker/wiki/Engine-1.11.0
# See https://docs.docker.com/engine/installation/binaries/
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
# install tini (for pid 1 zombie reaping) running foreman proxy
# https://github.com/krallin/tini
# https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/

RUN apk add --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ tini
CMD [ "/sbin/tini", "--", "foreman", "start", "-d", "/app" ]

ARG PORT
ENV PORT=${PORT}
EXPOSE ${PORT}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# install app

COPY . /app

