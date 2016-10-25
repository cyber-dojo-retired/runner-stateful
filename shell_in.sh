#!/bin/sh

user=${1:-cyber-dojo}

docker_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')

docker run \
  --rm \
  --user=${user} \
  --interactive \
  --tty \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  cyberdojo/runner:${docker_version} \
  sh
