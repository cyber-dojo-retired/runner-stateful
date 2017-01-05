#!/bin/bash

docker rm --force --volumes $(docker ps --quiet --filter 'name=cyber_dojo_')