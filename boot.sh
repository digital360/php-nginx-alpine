#!/bin/sh

# set php-fpm
/auto-fpm.sh >&2

# set nginx server info
SERVER_NAME=${VIRTUAL_HOST:-${SERVER_NAME:-localhost}}
envsubst '$SERVER_NAME $SERVER_ALIAS $SERVER_ROOT' < /nginx.conf.template > /etc/nginx/nginx.conf

supervisord -c /etc/supervisor.d/supervisord.ini