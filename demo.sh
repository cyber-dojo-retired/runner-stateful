#!/bin/sh
set -e

hash docker 2> /dev/null
if [ $? != 0 ]; then
  echo
  echo "docker is not installed"
  exit 1
fi

app_dir=/app
docker_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
server_port=4557
client_port=4558

# build base image
my_dir="$( cd "$( dirname "${0}" )" && pwd )"
${my_dir}/base/build-image.sh ${app_dir}

# build server image
docker-compose -f ${my_dir}/server/docker-compose.yml build

# build client image
${my_dir}/client/build-image.sh ${app_dir} ${client_port}

# bring server up
cat ${my_dir}/docker-compose.yml.PORT |
  sed "s/DOCKER_ENGINE_VERSION/${docker_version}/g" |
  sed "s/SERVER_PORT/${server_port}/g" |
  sed "s/CLIENT_PORT/${client_port}/g" > ${my_dir}/docker-compose.yml

docker-compose -f ${my_dir}/docker-compose.yml down
docker-compose -f ${my_dir}/docker-compose.yml up &

ip=$(docker-machine ip default)

echo "${ip}:${client_port}"
