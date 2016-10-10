#!/bin/sh
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
cd ${my_dir} && ./build.sh
ip=$(docker-machine ip default)
echo "${ip}:4558/diff"

docker-compose down
docker-compose up &
