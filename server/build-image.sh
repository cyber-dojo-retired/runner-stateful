#!/bin/sh

app_dir=${1:-/app}
docker_version=${2:-1.12.1}

image_name=cyberdojo/runner:${docker_version}
docker build --build-arg app_dir=${app_dir} --tag ${image_name} .
if [ $? != 0 ]; then
  echo "FAILED TO BUILD ${image_name}"
  exit 1
fi
