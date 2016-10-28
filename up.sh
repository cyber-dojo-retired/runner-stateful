#!/bin/bash
set -e

hash docker 2> /dev/null
if [ $? != 0 ]; then
  echo
  echo "docker is not installed"
  exit 1
fi

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
docker_engine_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
export DOCKER_ENGINE_VERSION=${docker_engine_version}

docker-compose -f ${my_dir}/docker-compose.yml down
docker-compose -f ${my_dir}/docker-compose.yml up &
