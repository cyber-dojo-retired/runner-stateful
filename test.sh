#!/bin/bash

server_cid=`docker ps --all --quiet --filter "name=runner_server"`
server_status=0

client_cid=`docker ps --all --quiet --filter "name=runner_client"`
client_status=0

# - - - - - - - - - - - - - - - - - - - - - - - - - -

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

run_server_tests()
{
  docker exec ${server_cid} sh -c "cd /app/test && ./run.sh ${*}"
  server_status=$?
  docker cp ${server_cid}:/tmp/coverage ${my_dir}/server
  echo "Coverage report copied to ${my_dir}/server/coverage"
  cat ${my_dir}/server/coverage/done.txt
}

run_client_tests()
{
  docker exec ${client_cid} sh -c "cd /app/test && ./run.sh ${*}"
  client_status=$?
  docker cp ${client_cid}:/tmp/coverage ${my_dir}/client
  echo "Coverage report copied to ${my_dir}/client/coverage"
  cat ${my_dir}/client/coverage/done.txt
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_server_tests ${*}
#run_client_tests ${*}

if [[ ( ${server_status} == 0 && ${client_status} == 0 ) ]]; then
  docker-compose down
  echo "------------------------------------------------------"
  echo "All passed"
  exit 0
else
  echo
  echo "server: cid = ${server_cid}, status = ${server_status}"
  if [ "${server_cid}" != "0" ]; then
    docker logs runner_server
  fi
  echo "client: cid = ${client_cid}, status = ${client_status}"
  if [ "${client_cid}" != "0" ]; then
    docker logs runner_client
  fi
  echo
  exit 1
fi
