FROM php:7-fpm-alpine AS prod

STOPSIGNAL SIGCONT

COPY ./boot.sh /sbin/boot.sh

# latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./auto-fpm.sh /auto-fpm.sh
COPY ./custom_nginx.conf /nginx.conf.template
COPY ./php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./custom_php.ini /usr/local/etc/php/php.ini

# Set up cron
COPY --chown=www-data:www-data ./crontab /var/spool/cron/crontabs/www-data
RUN chmod 0644 /var/spool/cron/crontabs/www-data && /usr/bin/crontab /var/spool/cron/crontabs/www-data

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
    tini \
    curl \
    runit \
    bash \
    gettext \
    dcron \
    nginx && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j "$(nproc)" gd tokenizer pcntl pdo pdo_mysql mysqli bcmath zip && \
    mkdir -p /var/cache/nginx && \
    chown -R www-data:www-data /var/cache/nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    chmod +x /sbin/boot.sh && \
    mkdir /etc/run_once && \
    docker-php-source delete && \
#   apk del .build-deps && \
    rm -rf /var/cache/apk/*

# runit related files
ADD ./runit /
RUN find /etc/service -name "run" -exec chmod +x {} \;

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