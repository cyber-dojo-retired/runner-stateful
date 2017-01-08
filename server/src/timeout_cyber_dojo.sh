#!/usr/bin/env sh
# NB: Alpine images do not have bash

KATA_ID=$1
AVATAR=$2
MAX_SECONDS=$3

export CYBER_DOJO_KATA_ID=${KATA_ID}
export CYBER_DOJO_AVATAR_NAME=${AVATAR}
export CYBER_DOJO_SANDBOX=/sandboxes/${AVATAR}

cd ${CYBER_DOJO_SANDBOX}

grep -q -c Alpine /etc/issue >/dev/null 2>&1
if [ $? -eq 0 ]; then
  su ${AVATAR} -p -c "timeout -s KILL -t ${MAX_SECONDS} sh ./cyber-dojo.sh"
  status=$?
fi

grep -q -c Ubuntu /etc/issue >/dev/null 2>&1
if [ $? -eq 0 ]; then
  su ${AVATAR} -p -c "timeout -s KILL ${MAX_SECONDS}s sh ./cyber-dojo.sh"
  status=$?
fi

# On Alpine's ps, the user's name is truncated to 8 chars
SHORT_AVATAR=`echo ${AVATAR} | cut -c -8`
ps -o user,pid | grep "^${SHORT_AVATAR}\s" | awk '{print $2}' | xargs kill -9
exit ${status}
