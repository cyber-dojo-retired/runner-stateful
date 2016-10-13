#!/bin/sh

# A runner that executes /sandbox/cyber-dojo.sh inside a prepared docker
# container and kills it if it does not complete in 10 seconds.

cid=$1         # Container ready to run /sandbox/cyber-dojo.sh
max_secs=$2    # How long cyber-dojo.sh has to complete, in seconds, eg 10
sudo=$3        # sudo incantation for docker commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. After max_seconds, remove the container
# o) Doing [docker stop ${CID}] is not enough to stop a container
#    that is printing in an infinite loop (for example).
# o) Any zombie processes this backgrounded process creates are reaped by tini.
#    See top of Dockerfile
# o) The parentheses puts the commands into a child process.
# o) The trailing & backgrounds it.
# o) Piping stdout and stderr of both sub-commands (&>) to dev/null ensures
#    that normal shell output [Terminated] from the pkill (6) is suppressed.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(sleep ${max_secs} &> /dev/null && ${sudo} docker rm --force ${cid} &> /dev/null) &
sleep_docker_rm_pid=$!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. Run cyber-dojo.sh
# Don't use the exit-status of cyber-dojo.sh
# Using it to determine red/amber/green status is unreliable
#   - not all test frameworks set their exit-status properly
#   - cyber-dojo.sh is editable (suppose it ended [exit 137])
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

output=$(${sudo} docker exec \
               --user=nobody \
               --interactive \
               ${cid} \
               sh -c "cd /sandbox && ./cyber-dojo.sh 2>&1")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. If the sleep-docker-rm process (1) is still alive race to
#    kill it before it does [docker rm ${cid}]
#      pkill   == kill processes
#      -P PID  == whose parent pid is PID
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pkill -P ${sleep_docker_rm_pid}
if [ "$?" != "0" ]; then
  # Failed to kill the sleep-docker-rm process
  # Assume [docker rm ${cid}] happened
  ${sudo} docker rm --force ${cid} &> /dev/null # belt and braces
  exit 137 # (128=timed-out) + (9=killed)
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 5. Check the container is still running (belt and braces)
#    We're aiming for
#      - the background 10-second kill process is dead
#      - the test-run container is still alive
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

running=$(${sudo} docker inspect --format="{{ .State.Running }}" ${cid})
if [ "${running}" != "true" ]; then
  exit 137 # (128=timed-out) + (9=killed)
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 6. We're not using the exit status of the container
#   Instead
#     - echo the output so it can be red/amber/green regex'd (see 5)
#     - remove the container
#     - exit 0
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "${output}"

${sudo} docker rm --force ${cid} &> /dev/null

exit 0
