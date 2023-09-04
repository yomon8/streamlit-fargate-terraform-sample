#!/bin/sh
docker inspect --format='{"id":"{{index .Id}}"}' $1:$2