#!/bin/sh
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
app_dir=/app
docker_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
server_port=4557
client_port=4558

${my_dir}/base/build-image.sh ${app_dir}
${my_dir}/server/build-image.sh ${app_dir} ${docker_version} ${server_port}
${my_dir}/client/build-image.sh ${app_dir} ${client_port}

cat ${my_dir}/docker-compose.yml.PORT |
  sed "s/DOCKER_ENGINE_VERSION/${docker_version}/g" |
  sed "s/SERVER_PORT/${server_port}/g" |
  sed "s/CLIENT_PORT/${client_port}/g" > ${my_dir}/docker-compose.yml

docker-compose down
docker-compose up &

sleep 1

ip=$(docker-machine ip default)

echo "${ip}:${client_port}"
