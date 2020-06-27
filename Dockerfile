FROM php:7-fpm-alpine

ARG S6_OVERLAY_RELEASE=https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz
ENV S6_OVERLAY_RELEASE=${S6_OVERLAY_RELEASE}

# s6 overlay Download
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz

ADD rootfs /

# Build and some of image configuration
RUN apk add --update --no-cache \
       bash \
       gettext \
       dcron \
       nginx \
    && docker-php-ext-install tokenizer pcntl \
    && docker-php-source delete \
    && mkdir -p /var/cache/nginx \
    && chown -R www-data:www-data /var/cache/nginx \
    && rm -rf /var/cache/apk/* \
    && tar xzf /tmp/s6overlay.tar.gz -C / \
    && rm /tmp/s6overlay.tar.gz

# Create web user user
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# setup .composer folder and set permissions
RUN  mkdir -p /var/www/.composer \
     && chown -R www-data:www-data /var/www/.composer

EXPOSE 80
WORKDIR /var/www/html

# Init
ENTRYPOINT [ "/init" ]