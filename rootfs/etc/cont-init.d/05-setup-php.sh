#!/usr/bin/with-contenv bash

# move php-fpm config
yes | cp -rf /confs/php/php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf

# move php.ini
yes | cp -rf /confs/php/custom_php.ini /usr/local/etc/php/php.ini

# set fpm process numbers
/confs/php/auto-fpm.sh >&2