#!/bin/sh

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
app_dir=${1}
docker_version=${2}
port=${3}

cat ${my_dir}/Dockerfile.PORT | sed "s/PORT/${port}/" > ${my_dir}/Dockerfile
cat ${my_dir}/Procfile.PORT   | sed "s/PORT/${port}/" > ${my_dir}/Procfile

image_name=cyberdojo/runner:${docker_version}
docker build --build-arg app_dir=${app_dir} --tag ${image_name} ${my_dir}
if [ $? != 0 ]; then
  echo "FAILED TO BUILD ${image_name}"
  exit 1
fi
