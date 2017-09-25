#!/bin/bash

# Brute-force script to remove all runner volumes.
# Useful during development when tests fails and leave
# volumes behind, whose mere existence then interferes with
# subsequent test runs.

# Kata-Volume-Runner
# o) creates a named volume per kata

NAME=cyber_dojo_kata_volume_runner_
docker rm --force --volumes $(docker ps --all --quiet --filter "name=${NAME}")
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")

docker rmi $(docker images -q --filter "dangling=true")