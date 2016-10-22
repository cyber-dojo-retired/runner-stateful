#!/bin/sh
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
app_dir=/app
docker_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
client_port=4558
server_port=4557

${my_dir}/base/build-image.sh ${app_dir}
${my_dir}/client/build-image.sh ${app_dir} ${client_port}
${my_dir}/server/build-image.sh ${app_dir} ${docker_version} ${server_port}

#${my_dir}/build_and_test.sh ${app_dir} ${docker_version} ${client_port} ${server_port}
ip=$(docker-machine ip default)
echo "${ip}:${client_port}"

export DOCKER_ENGINE_VERSION=${docker_version}
docker-compose down
docker-compose up &
