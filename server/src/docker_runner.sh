#!/bin/sh

# A runner that executes cyber-dojo.sh inside a prepared docker container
# and kills it if it does not complete in 10 seconds.

CID=$1         # container ready to run cyber-dojo.sh
MAX_SECS=$2    # How long they've got to complete in seconds, eg 10
SUDO=$3        # sudo incantation for docker commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. After max_seconds, remove the container
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# o) Doing [docker stop ${CID}] is not enough to stop a container
#    that is printing in an infinite loop (for example).
#
# o) Any zombie processes this backgrounded process creates are reaped by tini.
#    See top of runner/Dockerfile
#
# o) The parentheses puts the commands into a child process.
#
# o) The trailing & backgrounds it.
#
# o) Piping stdout and stderr of both sub-commands (&>) to dev/null ensures
#    that normal shell output [Terminated] from the pkill (6) is suppressed.

(sleep ${MAX_SECS} &> /dev/null && ${SUDO} docker rm --force ${CID} &> /dev/null) &
SLEEP_DOCKER_RM_PID=$!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. Run cyber-dojo.sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

OUTPUT=$(${SUDO} docker exec \
               --user=nobody \
               --interactive \
               ${CID} \
               sh -c "cd ${SANDBOX} && ./cyber-dojo.sh 2>&1")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. Don't use the exit-status of cyber-dojo.sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Using it to determine red/amber/green status is unreliable
#   - not all test frameworks set their exit-status properly
#   - cyber-dojo.sh is editable (suppose it ended [exit 137])

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 4. If the sleep-docker-rm process (3) is still alive race to
#    kill it before it does [docker rm ${CID}]
#      pkill   == kill processes
#      -P PID  == whose parent pid is PID
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pkill -P ${SLEEP_DOCKER_RM_PID}
if [ "$?" != "0" ]; then
  # Failed to kill the sleep-docker-rm process
  # Assume [docker rm ${CID}] happened
  ${SUDO} docker rm --force ${CID} &> /dev/null # belt and braces
  exit 137 # (128=timed-out) + (9=killed)
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 5. Check the CID container is still running (belt and braces)
#    We're aiming for
#      - the background 10-second kill process is dead
#      - the test-run container is still alive
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

RUNNING=$(${SUDO} docker inspect --format="{{ .State.Running }}" ${CID})
if [ "${RUNNING}" != "true" ]; then
  exit 137 # (128=timed-out) + (9=killed)
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 6. We're not using the exit status (5) of the test container
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   Instead
#     - echo the output so it can be red/amber/green regex'd (see 5)
#     - exit 0

echo "${OUTPUT}"

exit 0
