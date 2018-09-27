#!/bin/bash

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"
readonly MY_NAME="${ROOT_DIR##*/}"

readonly SERVER_CID=$(docker ps --all --quiet --filter "name=${MY_NAME}-server")
readonly CLIENT_CID=$(docker ps --all --quiet --filter "name=${MY_NAME}-client")

readonly COVERAGE_ROOT=/tmp/coverage

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_server_tests()
{
  echo
  echo 'Running server tests...'

  docker exec \
    --env COVERAGE_ROOT=${COVERAGE_ROOT} \
    "${SERVER_CID}" \
      sh -c "cd /app/test && ./run.sh ${*}"
  server_status=$?

  # You can't [docker cp] from a tmpfs, you have to tar-pipe out.
  docker exec "${SERVER_CID}" \
    tar Ccf \
      "$(dirname "${COVERAGE_ROOT}")" \
      - "$(basename "${COVERAGE_ROOT}")" \
        | tar Cxf "${ROOT_DIR}/server/" -

  echo "Coverage report copied to ${MY_NAME}/server/coverage/"
  cat "${ROOT_DIR}/server/coverage/done.txt"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_client_tests()
{
  echo
  echo 'Running client tests...'

  docker exec \
    --env COVERAGE_ROOT=${COVERAGE_ROOT} \
    "${CLIENT_CID}" \
      sh -c "cd /app/test && ./run.sh ${*}"
  client_status=$?

  # You can't [docker cp] from a tmpfs, you have to tar-pipe out.
  docker exec "${CLIENT_CID}" \
    tar Ccf \
      "$(dirname "${COVERAGE_ROOT}")" \
      - "$(basename "${COVERAGE_ROOT}")" \
        | tar Cxf "${ROOT_DIR}/client/" -

  echo "Coverage report copied to ${MY_NAME}/client/coverage/"
  cat "${ROOT_DIR}/client/coverage/done.txt"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ ! -z "${TRAVIS}" ]; then
  # on Travis - pull images used by tests
  docker pull cyberdojofoundation/gcc_assert
  docker pull cyberdojofoundation/csharp_nunit
  docker pull cyberdojofoundation/perl_test_simple
  docker pull cyberdojofoundation/python_pytest
fi

server_status=0
client_status=0

if [ "$1" = "server" ]; then
  shift
  run_server_tests "$@"
elif [ "$1" = "client" ]; then
  shift
  run_client_tests "$@"
else
  run_server_tests "$@"
  run_client_tests "$@"
fi

if [[ ( ${server_status} == 0 && ${client_status} == 0 ) ]];  then
  echo '------------------------------------------------------'
  echo 'All passed'
  exit 0
else
  echo
  echo "server: cid = ${server_cid}, status = ${server_status}"
  echo "client: cid = ${client_cid}, status = ${client_status}"
  echo
  exit 1
fi
