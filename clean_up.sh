#!/bin/bash

# The Kata-Container-Runner creates (per kata) a long-lived
# named container.
NAME=cyber_dojo_kata_container_runner_
docker rm --force --volumes $(docker ps --all --quiet --filter "name=${NAME}")

# The Kata-Volume-Runner creates (per kata) an unnamed
# volume insde an exited named data-container.
NAME=cyber_dojo_kata_volume_runner_
docker rm --force --volumes $(docker ps --all --quiet --filter "name=${NAME}")

# The Avatar-Volume-Runner creates (per avatar) an unnamed
# volume inside an exited named data-container.
#...

# pids=$(docker ps --all --quiet --filter 'status=exited' --filter 'name=...')
# echo ${pids} | xargs docker rm --force
