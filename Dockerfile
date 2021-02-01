###########################
# Shared tools
###########################

# full kimai source
FROM alpine:3.13.0 AS git
ARG VERSION=1.12
ARG CHECKSUM=511e8c9bab096cc900e122dbc8efbb7522ade647e2c1ebe3f0a2638c121b31dc
# I need to do this check somewhere, we discard all but the checkout so doing here doesn't hurt
COPY ./bin/test-kimai-version.sh /test-kimai-version.sh
WORKDIR /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  /test-kimai-version.sh && \
  apk add --no-cache \
    wget=1.21.1-r1 \
    unzip=6.0-r8 && \
  echo "**** download kimai ****" && \
  wget "https://github.com/kevinpapst/kimai2/releases/download/${VERSION}/kimai-release-${VERSION}.zip" && \
  echo "${CHECKSUM}  kimai-release-${VERSION}.zip" | sha256sum -c && \
  unzip "kimai-release-${VERSION}.zip" -d /opt/kimai
WORKDIR /opt/kimai

# composer base image
FROM composer:2.0.9 AS composer

###########################
# PHP extensions
###########################

#fpm alpine php extension base
FROM php:7.4.12-fpm-alpine3.12 AS fpm-alpine-php-ext-base
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    autoconf=2.69-r2 \
    dpkg=1.20.0-r0 \
    dpkg-dev=1.20.0-r0 \
    file=5.38-r0 \
    g++=9.3.0-r2 \
    gcc=9.3.0-r2 \
    libatomic=9.3.0-r2 \
    libc-dev=0.7.2-r3 \
    libgomp=9.3.0-r2 \
    libmagic=5.38-r0 \
    m4=1.4.18-r1 \
    make=4.3-r0 \
    mpc1=1.1.0-r1 \
    mpfr4=4.0.2-r4 \
    musl-dev=1.1.24-r10 \
    perl=5.30.3-r0 \
    re2c=1.3-r1 \
    freetype-dev=2.10.4-r0 \
    libpng-dev=1.6.37-r1 \
    icu-dev=67.1-r0 \
    openldap-dev=2.4.50-r1 \
    libldap=2.4.50-r1 \
    libzip-dev=1.6.1-r1 \
    libxslt-dev=1.1.34-r0 && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*

# php extension gd - 13.86s
FROM fpm-alpine-php-ext-base AS php-ext-gd
RUN \
  echo "**** install php extensions ****" && \
  docker-php-ext-configure gd --with-freetype && \
  docker-php-ext-install -j"$(nproc)" gd

# php extension intl : 15.26s
FROM fpm-alpine-php-ext-base AS php-ext-intl
RUN docker-php-ext-install -j"$(nproc)" intl

# php extension ldap : 8.45s
FROM fpm-alpine-php-ext-base AS php-ext-ldap
RUN \
  docker-php-ext-configure ldap && \
  docker-php-ext-install -j"$(nproc)" ldap

# php extension pdo_mysql : 6.14s
FROM fpm-alpine-php-ext-base AS php-ext-pdo_mysql
RUN docker-php-ext-install -j"$(nproc)" pdo_mysql

# php extension zip : 8.18s
FROM fpm-alpine-php-ext-base AS php-ext-zip
RUN docker-php-ext-install -j"$(nproc)" zip

# php extension xsl : ?.?? s
FROM fpm-alpine-php-ext-base AS php-ext-xsl
RUN docker-php-ext-install -j"$(nproc)" xsl

FROM php:7.4.12-fpm-alpine3.12 AS fpm-alpine-base
ARG TZ=America/Los_Angeles
ARG BUILD_DATE
ARG VERSION
ENV TZ=${TZ}
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde <ncwilde43@gmail.com>"
ENV VERSION=${VERSION}
ENV DATABASE_URL=sqlite:///%kernel.project_dir%/var/data/kimai.sqlite
ENV APP_SECRET=change_this_to_something_unique
# The default container name for nginx is nginx
ENV TRUSTED_PROXIES=nginx,localhost,127.0.0.1
ENV TRUSTED_HOSTS=nginx,localhost,127.0.0.1
ENV MAILER_FROM=kimai@example.com
ENV MAILER_URL=null://localhost
ENV ADMINPASS=
ENV ADMINMAIL=
ENV DB_TYPE=
ENV DB_USER=
ENV DB_PASS=
ENV DB_HOST=
ENV DB_PORT=
ENV DB_BASE=
ENV APP_ENV=prod

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    bash=5.0.17-r0 \
    freetype=2.10.4-r0 \
    haveged=1.9.8-r1 \
    icu=67.1-r0 \
    libldap=2.4.50-r1 \
    libpng=1.6.37-r1 \
    libzip=1.6.1-r1 \
    libxslt-dev=1.1.34-r0 \
    fcgi=2.4.2-r0 \
    tzdata=2020f-r0 && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/* && \
  touch /use_fpm && \
  # make composer home dir
  mkdir /composer  && \
  chown -R www-data:www-data /composer

# copy startup script
COPY ./bin/entrypoint.sh /entrypoint.sh

# copy composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# copy php extensions
# PHP extension xsl
COPY --from=php-ext-xsl /usr/local/etc/php/conf.d/docker-php-ext-xsl.ini /usr/local/etc/php/conf.d/docker-php-ext-xsl.ini
COPY --from=php-ext-xsl /usr/local/lib/php/extensions/no-debug-non-zts-20190902/xsl.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/xsl.so
# PHP extension pdo_mysql
COPY --from=php-ext-pdo_mysql /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini
COPY --from=php-ext-pdo_mysql /usr/local/lib/php/extensions/no-debug-non-zts-20190902/pdo_mysql.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/pdo_mysql.so
# PHP extension zip
COPY --from=php-ext-zip /usr/local/etc/php/conf.d/docker-php-ext-zip.ini /usr/local/etc/php/conf.d/docker-php-ext-zip.ini
COPY --from=php-ext-zip /usr/local/lib/php/extensions/no-debug-non-zts-20190902/zip.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/zip.so
# PHP extension ldap
COPY --from=php-ext-ldap /usr/local/etc/php/conf.d/docker-php-ext-ldap.ini /usr/local/etc/php/conf.d/docker-php-ext-ldap.ini
COPY --from=php-ext-ldap /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ldap.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ldap.so
# PHP extension gd
COPY --from=php-ext-gd /usr/local/etc/php/conf.d/docker-php-ext-gd.ini /usr/local/etc/php/conf.d/docker-php-ext-gd.ini
COPY --from=php-ext-gd /usr/local/lib/php/extensions/no-debug-non-zts-20190902/gd.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/gd.so
# PHP extension intl
COPY --from=php-ext-intl /usr/local/etc/php/conf.d/docker-php-ext-intl.ini /usr/local/etc/php/conf.d/docker-php-ext-intl.ini
COPY --from=php-ext-intl /usr/local/lib/php/extensions/no-debug-non-zts-20190902/intl.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/intl.so
# copy kimai production source
COPY --from=git --chown=www-data:www-data /opt/kimai /opt/kimai
COPY ./config/monolog-prod.yaml /opt/kimai/config/packages/prod/monolog.yaml

RUN \
  echo "**** install composer deps ****" && \  
  export COMPOSER_HOME=/composer && \
  composer --no-ansi install --working-dir=/opt/kimai --no-dev --optimize-autoloader && \
  composer --no-ansi clearcache && \
  composer --no-ansi require --working-dir=/opt/kimai laminas/laminas-ldap && \
  cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
  chown -R www-data:www-data /opt/kimai
USER www-data

VOLUME [ "/opt/kimai/var" ]
EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
