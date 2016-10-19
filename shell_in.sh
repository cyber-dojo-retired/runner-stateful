#!/bin/sh

docker run \
  --rm \
  --user=nobody \
  --interactive \
  --tty \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  cyberdojo/runner:1.12.2 \
  sh
