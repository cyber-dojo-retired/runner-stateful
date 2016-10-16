#!/bin/sh

hash docker 2> /dev/null
if [ $? != 0 ]; then
  echo
  echo "docker is not installed"
  exit 1
fi

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
app_dir=${1}
docker_version=${2}
client_port=${3}
server_port=${4}

cd ${my_dir}/base    && ./build-image.sh ${app_dir}
cd ${my_dir}/client  && ./build-image.sh ${app_dir} ${client_port}
cd ${my_dir}/server  && ./build-image.sh ${app_dir} ${docker_version} ${server_port}

docker images | grep runner