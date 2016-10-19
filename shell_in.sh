#!/bin/sh

user=${1:-cyber-dojo}

docker run \
  --rm \
  --user=${user} \
  --interactive \
  --tty \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  cyberdojo/runner:1.12.2 \
  sh
