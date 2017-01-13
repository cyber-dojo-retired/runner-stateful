#!/bin/bash

NAME=cyber_dojo_kata_container_runner_
docker rm --force $(docker ps --all --quiet --filter "name=${NAME}")

NAME=cyber_dojo_kata_volume_runner_
docker rm --force --volumes $(docker ps --all --quiet --filter "name=${NAME}")

#avatar_volume_runner_
#...

# pids=$(docker ps --all --quiet --filter 'status=exited' --filter 'name=...')
# echo ${pids} | xargs docker rm --force
