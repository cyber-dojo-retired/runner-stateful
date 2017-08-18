#!/bin/bash

# During development, when a test fails it
# can leave containers/volumes around.
# I'd like to leave the containers/volumes
# for a failed test unremoved since that way I
# can shell in (eg for debugging). So I don't
# do a teardown at the end of each test. Instead
# I do a big teardown before all the tests run.

readonly ZOMBIE_CONTAINERS=$(docker ps --all --filter "name=test_run__runner_stateful_" --format "{{.Names}}")
if [ "${ZOMBIE_CONTAINERS}" != "" ]; then
  docker rm --force --volumes ${ZOMBIE_CONTAINERS}
fi

readonly ZOMBIE_VOLUMES=$(docker volume ls --quiet --filter "name=cyber_dojo_kata_value_runner_")
if [ "${ZOMBIE_VOLUMES}" != "" ]; then
  docker volume rm --force ${ZOMBIE_VOLUMES}
fi
