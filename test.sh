#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

server_cid=`docker ps --all --quiet --filter "name=runner_server"`
server_status=0

client_cid=`docker ps --all --quiet --filter "name=runner_client"`
client_status=0

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_server_tests()
{
  docker exec ${server_cid} sh -c "cd /app/test && ./run.sh ${*}"
  server_status=$?
  docker cp ${server_cid}:/tmp/coverage ${my_dir}/server
  echo "Coverage report copied to ${my_dir}/server/coverage"
  cat ${my_dir}/server/coverage/done.txt
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_client_tests()
{
  docker exec ${client_cid} sh -c "cd /app/test && ./run.sh ${*}"
  client_status=$?
  # Client Coverage is broken. Simplecov is not seeing the test/src/*_test.rb files
  #docker cp ${client_cid}:/tmp/coverage ${my_dir}/client
  #echo "Coverage report copied to ${my_dir}/client/coverage"
  #cat ${my_dir}/client/coverage/done.txt
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_server_tests ${*}
run_client_tests ${*}

if [[ ( ${server_status} == 0 && ${client_status} == 0 ) ]];  then
  docker_engine_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
  echo "------------------------------------------------------"
  echo "All passed"
  echo "------------------------------------------------------"
  export DOCKER_ENGINE_VERSION=${docker_engine_version}
  docker-compose down
  exit 0
else
  echo
  echo "server: cid = ${server_cid}, status = ${server_status}"
  echo "client: cid = ${client_cid}, status = ${client_status}"
  echo
  exit 1
fi
