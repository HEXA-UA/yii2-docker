FROM php:7.1-fpm
MAINTAINER Hexa "info@hexa.com.ua"

ENV DEBIAN_FRONTEND=noninteractive

ENV PATH=/app:/app/vendor/bin:/root/.composer/vendor/bin:$PATH \
    VERSION_PRESTISSIMO_PLUGIN=^0.3.7 \
    VERSION_PHING=2.* \
    VETSION_PHPCS=3.4.2 \
    COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update && \
    apt-get -y install \
        gnupg2 && \
    apt-get update && \
    apt-get -y install \
            g++ \
            git \
            curl \
            imagemagick \
            libfreetype6-dev \
            libcurl3-dev \
            libicu-dev \
            libfreetype6-dev \
            libjpeg-dev \
            libmcrypt-dev \
            libjpeg62-turbo-dev \
            libmagickwand-dev \
            libpq-dev \
            procps \
            libpng-dev \
            libxml2-dev \
            zlib1g-dev \
            mysql-client \
            openssh-client \
            ldap-utils \
            libldap2-dev \
            nano \
            unzip \
            libgeoip-dev \
            wget \
            xvfb \
            net-tools \
        --no-install-recommends && \
        apt-get clean

RUN pecl install xdebug-2.6.0 \
    && docker-php-ext-enable xdebug

RUN pecl install geoip-1.1.1 \
    && docker-php-ext-enable geoip

RUN docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-configure bcmath && \
    docker-php-ext-install \
        soap \
        zip \
        mcrypt \
        curl \
        bcmath \
        exif \
        gd \
        iconv \
        intl \
        mbstring \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        ldap

# Install composer
RUN apt-get purge -y g++ \
    && apt-get autoremove -y \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer clear-cache

# Install composer plugins
RUN composer global require --optimize-autoloader \
        "hirak/prestissimo:${VERSION_PRESTISSIMO_PLUGIN}" \
        && composer global dumpautoload --optimize \
        && composer clear-cache

RUN composer global require --optimize-autoloader \
        "phing/phing:${VERSION_PHING}" \
        && composer global dumpautoload --optimize \
        && composer clear-cache

RUN composer global require --optimize-autoloader \
        "squizlabs/php_codesniffer:${VETSION_PHPCS}" \
        && composer global dumpautoload --optimize \
        && composer clear-cache

# Install nodejs, webpack
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs build-essential
RUN npm install -g webpack
RUN npm install -g aglio --unsafe-perm

RUN mkdir -p /usr/share/GeoIP/

RUN wget -N https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
RUN tar -xzf GeoLite2-Country.tar.gz -C /usr/share/GeoIP/

RUN curl -LO https://deployer.org/deployer.phar
RUN mv deployer.phar /usr/local/bin/dep
RUN chmod +x /usr/local/bin/dep

ENV TZ 'UTC'
RUN echo $TZ > /etc/timezone \
    && apt-get update && apt-get install -y tzdata && \
    rm /etc/localtime && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean

