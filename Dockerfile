FROM php:7-fpm-alpine

STOPSIGNAL SIGCONT

# Create user
RUN adduser -D -u 1000 -g 1000 -s /bin/sh www-data && \
    mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# setup .composer folder and set permissions
RUN  mkdir -p /var/www/.composer && \
  chown -R www-data:www-data /var/www/.composer

# NGINX
ARG SERVER_NAME
ARG SERVER_ALIAS
ARG SERVER_ROOT

ENV SERVER_NAME $SERVER_NAME
ENV SERVER_ALIAS $SERVER_ALIAS
ENV SERVER_ROOT $SERVER_ROOT

COPY boot.sh /sbin/boot.sh

# latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY auto-fpm.sh /auto-fpm.sh
COPY custom_nginx.conf /nginx.conf.template
COPY php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf
COPY custom_php.ini /usr/local/etc/php/php.ini

# Set up cron
COPY crontab /var/spool/cron/crontabs/custom
RUN /usr/bin/crontab /var/spool/cron/crontabs/custom

# Install nginx & gettext (envsubst)
# Create cachedir and fix permissions
RUN set -xe && \
	apk add --update --no-cache && \
# Install tini - 'cause zombies - see: https://github.com/ochinchina/supervisord/issues/60
# (also pkill hack)
    apk add \
    tini \
    runit \
    bash \
    gettext \
    dcron \
    nginx && \
    docker-php-ext-install tokenizer pcntl && \
    docker-php-source delete && \
    mkdir -p /var/cache/nginx && \
    chown -R www-data:www-data /var/cache/nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    chmod +x /sbin/boot.sh && \
    mkdir /etc/run_once && \
    rm -rf /var/cache/apk/*

# runit related files
ADD runit /
RUN find /etc/service -name "run" -exec chmod +x {} \;

EXPOSE 80
WORKDIR /var/www/html

# reset the user
USER $USER

ENTRYPOINT ["tini", "--"]
CMD [ "/sbin/boot.sh" ]