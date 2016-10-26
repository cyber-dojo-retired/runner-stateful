#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
${my_dir}/build.sh
${my_dir}/up.sh

echo "$(docker-machine ip default):4558"
