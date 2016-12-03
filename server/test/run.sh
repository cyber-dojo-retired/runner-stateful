#!/bin/bash

if [ ! -f /.dockerenv ]; then
  echo 'FAILED: run.sh is being executed outside of docker-container.'
  echo 'Use pipe_build_up_test.sh'
  exit 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# server

rm -rf /tmp/cyber-dojo
mkdir /tmp/cyber-dojo

cov_dir=/tmp/coverage
rm -rf ${cov_dir}
mkdir ${cov_dir}
test_log=${cov_dir}/test.log

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
cd ${my_dir}/src
files=(*_test.rb)
args=(${*})
ruby -e "([ '../coverage.rb' ] + %w(${files[*]}).shuffle).each{ |file| require './'+file }" -- ${args[@]} | tee ${test_log}
cd ${my_dir} && ruby ./check_test_results.rb ${test_log} ${cov_dir}/index.html > ${cov_dir}/done.txt
