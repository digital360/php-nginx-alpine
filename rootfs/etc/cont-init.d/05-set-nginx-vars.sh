#!/usr/bin/with-contenv bash

# reset the PHP memory limit
# set nginx server info
SERVER_NAME=${VIRTUAL_HOST:-${SERVER_NAME:-localhost}}
# shellcheck disable=SC2016
envsubst '$SERVER_NAME $SERVER_ALIAS $SERVER_ROOT' < /confs/nginx/nginx.conf.template > /etc/nginx/nginx.conf