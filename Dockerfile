FROM php:8-fpm-alpine AS prod

STOPSIGNAL SIGCONT

COPY ./boot.sh /sbin/boot.sh

# latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./auto-fpm.sh /auto-fpm.sh
RUN chmod +x /auto-fpm.sh

COPY ./custom_nginx.conf /nginx.conf.template
COPY ./php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./custom_php.ini /usr/local/etc/php/php.ini

ENV PHPIZE_DEPS \
    autoconf \
    file \
    g++ \
    make \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev

# Install nginx & gettext (envsubst)
# Create cachedir and fix permissions
RUN set -xe && \
	apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    apk add \
    busybox-suid \
    tini \
    curl \
    bash \
    gettext \
    supervisor \
    nginx && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j "$(nproc)" gd tokenizer pcntl pdo pdo_mysql mysqli bcmath zip && \
    mkdir -p /var/cache/nginx && \
    chown -R www-data:www-data /var/cache/nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    chmod +x /sbin/boot.sh && \
    mkdir /etc/run_once && \
    docker-php-source delete && \
    rm -rf /var/cache/apk/*

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY ./supervisor/supervisord.ini /etc/supervisor.d/supervisord.ini

RUN mkdir -p /run/nginx

# setup php
RUN mkdir -p /run/php/
RUN touch /run/php/php-fpm.pid

# Setup docroot
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# setup .composer folder and set permissions
RUN  mkdir -p /var/www/.composer && \
  chown -R www-data:www-data /var/www/.composer

EXPOSE 80
WORKDIR /var/www/html
USER www-data

# reset the user
USER root

# Set up cron
COPY --chown=www-data:www-data ./crontab /var/spool/cron/crontabs/www-data
RUN /usr/bin/crontab /var/spool/cron/crontabs/www-data

ENTRYPOINT ["tini", "--", "/sbin/boot.sh"]