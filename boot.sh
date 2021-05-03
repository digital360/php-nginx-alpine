#!/bin/sh

# set php-fpm
/auto-fpm.sh >&2

# set nginx server info
sed -i -e "s|_localhost_|${SERVER_ALIAS:=localhost}|g; s|_root_|${SERVER_ROOT:=/var/www/html/public}|g" /etc/nginx/nginx.conf

supervisord -c /etc/supervisor.d/supervisord.ini