#!/bin/sh
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
app_dir=/app
docker_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
client_port=4558
server_port=4557

${my_dir}/build.sh ${app_dir} ${docker_version} ${client_port} ${server_port}
ip=$(docker-machine ip default)
echo "${ip}:${client_port}"

export DOCKER_ENGINE_VERSION=${docker_version}
export CLIENT_PORT=${client_port}
export SERVER_PORT=${server_port}
docker-compose down
docker-compose up &
