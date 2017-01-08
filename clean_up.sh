#!/bin/bash

docker rm --force --volumes $(docker ps --quiet --filter 'name=cyber_dojo_')

# collector can do this
# - - - - - - - - - - -
# pids=$(docker ps --quiet --filter 'status=exited' --filter 'name=cyber_dojo_kata_')
# echo ${pids} | xargs docker rm --force --volumes
