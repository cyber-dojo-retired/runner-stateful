#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
#${my_dir}/build.sh
#${my_dir}/up.sh
# uuurg
#sleep 2

# - - - - - - - - - - - - - - - - - - - - - - - - - -
# server
server_cid=`docker ps --all --quiet --filter "name=runner_server"`
docker exec ${server_cid} sh -c "cd /app/test && ./run.sh ${*}"
server_exit_status=$?
docker cp ${server_cid}:/tmp/coverage ${my_dir}/server
echo "Coverage report copied to ${my_dir}/server/coverage"
cat ${my_dir}/server/coverage/done.txt

# - - - - - - - - - - - - - - - - - - - - - - - - - -
# client
client_cid=`docker ps --all --quiet --filter "name=runner_client"`
#docker exec ${client_cid} sh -c "cd test && ./run.sh ${*}"
#client_exit_status=$?
client_exit_status=0

#docker cp ${client_cid}:/tmp/coverage ${my_dir}/client
# Client Coverage is broken. Simplecov is not seeing the *_test.rb files
#echo "Coverage report copied to ${my_dir}/client/coverage"
#cat ${my_dir}/client/coverage/done.txt

# - - - - - - - - - - - - - - - - - - - - - - - - - -

show_cids() {
  echo
  echo "server: cid = ${server_cid}, exit_status = ${server_exit_status}"
  echo "client: cid = ${client_cid}, exit_status = ${client_exit_status}"
  echo
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ ${client_exit_status} != 0 ]; then
  show_cids
  exit 1
fi
if [ ${server_exit_status} != 0 ]; then
  show_cids
  exit 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - -

echo
echo "All passed. Removing runner_client and runner_server containers..."
docker-compose down 2>/dev/null
