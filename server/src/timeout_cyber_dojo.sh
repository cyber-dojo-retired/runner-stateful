#!/usr/bin/env sh
# NB: Alpine images do not have bash

KATA_ID=$1
AVATAR=$2
MAX_SECONDS=$3

alpine_kill_tree() # This does not work
{
  local pid=${1} child
  for child in $(pgrep -P ${pid});
  do
      alpine_kill_tree ${child}
  done
  [ ${pid} -ne $$ ] && kill -kill ${pid}
}

# - - - - - - - - - - - - - - - - - - - - -

ubuntu_kill_tree() # This works
{
    local pid=${1} child
    for child in $(pgrep -P ${pid});
    do
        ubuntu_kill_tree ${child}
    done
    [ ${pid} -ne $$ ] && kill -kill ${pid}
}

# - - - - - - - - - - - - - - - - - - - - -

export CYBER_DOJO_KATA_ID=${KATA_ID}
export CYBER_DOJO_AVATAR_NAME=${AVATAR}
export CYBER_DOJO_SANDBOX=/sandboxes/${AVATAR}

cd ${CYBER_DOJO_SANDBOX}

grep -q -c Alpine /etc/issue
if [ $? -eq 0 ]; then
  su ${AVATAR} -p -c "timeout -s KILL -t ${MAX_SECONDS} sh ./cyber-dojo.sh"
  status=$?
  alpine_kill_tree $$
  exit ${status}
fi

grep -q -c Ubuntu /etc/issue
if [ $? -eq 0 ]; then
  su ${AVATAR} -p -c "timeout -s KILL ${MAX_SECONDS}s sh ./cyber-dojo.sh"
  status=$?
  ubuntu_kill_tree $$
  exit ${status}
fi

