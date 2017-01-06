#!/usr/bin/env sh
# NB: Alpine images do not have bash

KATA_ID=$1
AVATAR=$2

export CYBER_DOJO_KATA_ID=${KATA_ID}
export CYBER_DOJO_AVATAR_NAME=${AVATAR}

cd /sandboxes/${CYBER_DOJO_AVATAR_NAME}

# Timeout's not tested yet.

grep -q -c Alpine /etc/issue
if [ $? -eq 0 ]; then
  su ${AVATAR} -p -c 'timeout -s TERM -t 10 ./cyber-dojo.sh'
  exit $?
fi

grep -q -c Ubuntu /etc/issue
if [ $? -eq 0 ]; then
  su ${AVATAR} -p -c 'timeout -s TERM 10s ./cyber-dojo.sh'
  exit $?
fi
