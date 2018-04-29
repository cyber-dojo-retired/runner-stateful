#!/bin/bash

# During development, when a test fails it
# can leave containers/volumes around.
# I'd like to leave the containers/volumes
# for a failed test unremoved since that way I
# can shell in (eg for debugging). So I don't
# do a teardown at the end of each test. Instead
# I do a big teardown before all the tests run.

readonly PREFIX=test_run__runner_stateful_

readonly ZOMBIE_CONTAINERS=$(docker ps --all --filter "name=${PREFIX}" --format "{{.Names}}")
if [ "${ZOMBIE_CONTAINERS}" != "" ]; then
  echo "zombie containers being removed..."
  docker rm --force --volumes "${ZOMBIE_CONTAINERS}"
fi

readonly ZOMBIE_VOLUMES=$(docker volume ls --quiet --filter "name=${PREFIX}")
if [ "${ZOMBIE_VOLUMES}" != "" ]; then
  echo "zombie volumes being removed..."
  docker volume rm --force "${ZOMBIE_VOLUMES}"
fi
