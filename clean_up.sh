#!/bin/bash

# Brute-force script to remove all runner volumes.
# Useful during development when tests fails and leave
# volumes behind, whose mere existence then interferes with
# subsequent test runs.

# Kata-Container-Runner
# o) creates named volume per kata.
# o) creates a long-lived named container per kata.
NAME=cyber_dojo_kata_container_runner_
docker rm --force --volumes $(docker ps --all --quiet --filter "name=${NAME}")
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")

# Kata-Volume-Runner
# o) creates a named volume per kata
NAME=cyber_dojo_kata_volume_runner_
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")

# Avatar-Volume-Runner
# o) creates a named volume per kata
# o) creates a named volume per avatar
NAME=cyber_dojo_avatar_volume_runner_kata_
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")

NAME=cyber_dojo_avatar_volume_runner_avatar_
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")
