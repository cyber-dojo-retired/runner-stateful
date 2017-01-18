#!/bin/bash

# Simple brute-force script to remove all local runner volumes
# Useful during development when tests fails and leave
# volumes behind, whose mere existence then interferes with
# subsequent test runs.

# The Kata-Container-Runner creates (per kata) a long-lived
# named container.
NAME=cyber_dojo_kata_container_runner_
docker rm --force --volumes $(docker ps --all --quiet --filter "name=${NAME}")

# The Kata-Volume-Runner creates a named volume per kata
NAME=cyber_dojo_kata_volume_runner_
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")

# The Avatar-Volume-Runner creates a named volume per kata and per avatar
NAME=cyber_dojo_avatar_volume_runner_kata_
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")

NAME=cyber_dojo_avatar_volume_runner_avatar_
docker volume rm $(docker volume ls --quiet --filter "name=${NAME}")
