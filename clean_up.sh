#!/bin/bash

# DockerKataContainerRunner
docker rm --force $(docker ps -all --quiet --filter 'name=cyber_dojo_kata')

# DockerKataVolumeRunner
docker rm --force --volumes $(docker ps --all --quiet --filter 'name=cyber_dojo_')



# collector can do this
# - - - - - - - - - - -
# pids=$(docker ps --all --quiet --filter 'status=exited' --filter 'name=cyber_dojo_kata_')
# echo ${pids} | xargs docker rm --force
