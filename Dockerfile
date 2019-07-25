FROM alpine:edge as base
LABEL builder=true

# Create user
RUN adduser -D -u 1000 -g 1000 -s /bin/sh www-data && \
    mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# setup .composer folder and set permissions
RUN  mkdir -p /var/www/.composer && \
  chown -R www-data:www-data /var/www/.composer

# Install a golang port of supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/bin/supervisord

# latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# persistent / runtime deps
ENV PHPIZE_DEPS \
		autoconf \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
		php7-dev

# Install nginx & gettext (envsubst)
# Create cachedir and fix permissions
RUN set -xe \
	&& apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
# Install tini - 'cause zombies - see: https://github.com/ochinchina/supervisord/issues/60
# (also pkill hack)
    && apk add \
	git \
	snappy-dev \
    tini \
    gettext \
    dcron \
    nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R www-data:www-data /var/cache/nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    # Install PHP/FPM + Modules
    apk add \
    php7 \
    php7-apcu \
    php7-pear \
    php7-bcmath \
    php7-bz2 \
    php7-cgi \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-oauth \
    php7-opcache \
    php7-openssl \
    php7-pcntl \
    php7-pdo \
    php7-phar \
    php7-redis \
    php7-session \
    php7-soap \
    php7-simplexml \
    php7-tokenizer \
    php7-xmlwriter \
    php7-zip \
    php7-zlib \
    && pecl install mongodb \
    && echo "extension=mongodb.so" > /etc/php7/conf.d/mongodb.ini \
    # install php ext for snappy compressions
    && git clone --recursive --depth=1 https://github.com/kjdev/php-ext-snappy.git \
    && cd php-ext-snappy \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && echo "extension=snappy.so" > /etc/php7/conf.d/snappy.ini \
    # Remove build and dev files
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

# Runtime env vars are envstub'd into config during entrypoint
ENV SERVER_NAME="localhost"
ENV SERVER_ALIAS=""
ENV SERVER_ROOT=/var/www/html

# Alias defaults to empty, example usage:
# SERVER_ALIAS='www.example.com'

COPY auto-fpm.sh /auto-fpm.sh
COPY supervisord.conf /supervisord.conf
COPY php-fpm-www.conf /etc/php7/php-fpm.d/www.conf
COPY nginx.conf.template /nginx.conf.template
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

# Install composer helper to speed up download packages
USER www-data
RUN composer global require hirak/prestissimo --no-plugins --no-scripts

# reset the user
USER $USER

# Nginx on :80
EXPOSE 80
WORKDIR /var/www/html
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
