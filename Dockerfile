FROM php:7-fpm-alpine

STOPSIGNAL SIGCONT

# NGINX
ARG SERVER_NAME
ARG SERVER_ALIAS
ARG SERVER_ROOT

ENV SERVER_NAME $SERVER_NAME
ENV SERVER_ALIAS $SERVER_ALIAS
ENV SERVER_ROOT $SERVER_ROOT

COPY docker/boot.sh /sbin/boot.sh

# latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY auto-fpm.sh /auto-fpm.sh
COPY custom_nginx.conf /nginx.conf.template
COPY php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf
COPY custom_php.ini /usr/local/etc/php/conf.d/php.ini

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
COPY runit/etc/service /etc/service

# Create user
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# setup .composer folder and set permissions
RUN  mkdir -p /var/www/.composer && \
  chown -R www-data:www-data /var/www/.composer

EXPOSE 80
WORKDIR /var/www/html
USER www-data

# reset the user
USER $USER

ENTRYPOINT ["tini", "--"]
CMD [ "/sbin/boot.sh" ]