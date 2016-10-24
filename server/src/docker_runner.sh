#!/bin/sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Executes /sandbox/cyber-dojo.sh inside a docker container ${cid}
# prepared by docker_runner.rb
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If it completes within max_seconds
#   o) the container is removed
#   o) it prints the output of cyber-dojo.sh's execution
#   o) it's exit status is 0 (success)
#
# If it fails to complete within max_seconds
#   o) the container is removed
#   o) it prints no output
#   o) it's exit status is 137 (see below)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# There are two places that run
#   docker rm --force ${cid} &> /dev/null
# I've tried putting that into a method to remove duplication
# and it causes tests to fail. I have no idea why!
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cid=$1         # Container ready to run /sandbox/cyber-dojo.sh
max_secs=$2    # How long cyber-dojo.sh has to complete, in seconds, eg 10

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. After max_seconds, assume an infinite loop and remove the container
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# o) Doing [docker stop ${CID}] is not enough to quickly stop a container
#    that is printing in an infinite loop (for example).
# o) Any zombie processes this backgrounded process creates are reaped by tini.
#    See top of cyberdojo/runner's Dockerfile
# o) The () puts everything between the () into a child process.
# o) The trailing & backgrounds the child process.
# o) Pipe stdout and stderr (&>) of both sub-commands to dev/null so normal
#    shell output [Terminated] from the pkill (3) is suppressed from output.
# o) Since this removes the container I've chosen to make this shell script
#    always remove the container (see 3).
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(sleep ${max_secs} &> /dev/null && docker rm --force ${cid} &> /dev/null) &
sleep_docker_rm_pid=$!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. Run cyber-dojo.sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# But don't use its exit-status to determine the red/green outcome.
# o) I don't want to rely on all test frameworks setting their exit-status properly
# o) I want amber as well
# o) cyber-dojo.sh is editable (suppose it ended [exit 137])
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

output=$(docker exec \
               --user=nobody \
               --interactive \
               ${cid} \
               sh -c "cd /sandbox && ./cyber-dojo.sh 2>&1")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. Is the sleep-docker-rm process (1) still alive?
# o) find out by trying to kill it
# o) [pkill -P PID] kills processes whose parent pid is PID
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pkill -P ${sleep_docker_rm_pid} &> /dev/null
if [ "$?" != "0" ]; then
  # We did not kill it. So...
  # o) it was no longer alive
  # o) cyber-dojo.sh did not complete within max seconds
  # o) the container has been removed
  timed_out_and_killed=137 # (128=timed-out) + (9=killed)
  exit ${timed_out_and_killed}
else
  # We did kill it. So...
  # o) it was still alive
  # o) cyber-dojo.sh did complete within max_seconds
  # o) the container has not been removed, so remove it (see 1)
  docker rm --force ${cid} &> /dev/null
  echo "${output}"
  success=0
  exit ${success}
fi
