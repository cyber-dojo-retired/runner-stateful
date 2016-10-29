#!/bin/bash
set -e

./build.sh
./up.sh
sleep 2
./test.sh ${*}