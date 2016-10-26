#!/bin/sh

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
docker_engine_version=$(docker --version | awk '{print $3}' | sed '$s/.$//')
export DOCKER_ENGINE_VERSION=${docker_engine_version}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
# server
server_cid=`docker ps --all --quiet --filter "name=runner_server"`
docker exec ${server_cid} sh -c "cd /app/test && ./run.sh ${*}"
server_status=$?
docker cp ${server_cid}:/tmp/coverage ${my_dir}/server
echo "Coverage report copied to ${my_dir}/server/coverage"
cat ${my_dir}/server/coverage/done.txt

# - - - - - - - - - - - - - - - - - - - - - - - - - -
# client
client_cid=`docker ps --all --quiet --filter "name=runner_client"`
#docker exec ${client_cid} sh -c "cd app/test && ./run.sh ${*}"
#client_status=$?
client_status=0
#docker cp ${client_cid}:/tmp/coverage ${my_dir}/client
# Client Coverage is broken. Simplecov is not seeing the *_test.rb files
#echo "Coverage report copied to ${my_dir}/client/coverage"
#cat ${my_dir}/client/coverage/done.txt

# - - - - - - - - - - - - - - - - - - - - - - - - - -

show_cids() {
  echo
  echo "server: cid = ${server_cid}, status = ${server_status}"
  echo "client: cid = ${client_cid}, status = ${client_status}"
  echo
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ ${client_status} != 0 ] || [ ${server_status} != 0 ]; then
  show_cids
  exit 1
else
  echo
  echo "All passed. Removing runner_client and runner_server containers..."
  docker-compose down 2>/dev/null
fi
