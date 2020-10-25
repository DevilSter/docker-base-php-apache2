ARG PHP_VERSION=7.4

FROM php:7.4-apache-buster

LABEL maintainer="Devil.Ster.1"
LABEL version="1.0.1"

ARG BUILD_VER=20201024
ARG PHP_VERSION=${PHP_VERSION}

# START Install Additional Soft
RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        postgresql-client \
        curl \
        wget \
        unzip \
        make \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# END Install Additional Soft

# START PHP Modules Install
RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        libxml2-dev \
    && docker-php-ext-install -j$(nproc) xmlrpc \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        libpspell-dev \
    && docker-php-ext-install -j$(nproc) pspell \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
       libzip-dev \
    && docker-php-ext-install -j$(nproc) zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        \
    && docker-php-ext-install -j$(nproc) bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
       libbz2-dev \
    && docker-php-ext-install -j$(nproc) bz2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        \
    && docker-php-ext-install -j$(nproc) calendar \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        \
    && docker-php-ext-install -j$(nproc) opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        \
    && docker-php-ext-install -j$(nproc) gettext \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
       libldap-dev \
    && docker-php-ext-install -j$(nproc) ldap \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -x && \
    apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
       unixodbc-dev \
    && docker-php-source extract \
    && cd /usr/src/php/ext/odbc \
    && phpize \
    && sed -ri 's@^ *test +"\$PHP_.*" *= *"no" *&& *PHP_.*=yes *$@#&@g' configure \
    && ./configure --with-unixODBC=shared,/usr \
    && docker-php-ext-install odbc \
    && docker-php-source delete \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
       libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install -j$(nproc) pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
       libmemcached-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# END PHP Modules Install

# START Composer Install
RUN rm -f /usr/local/bin/composer
RUN php -r "copy('https://getcomposer.org/installer', '/composer-setup.php');"
RUN php /composer-setup.php
RUN mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer
RUN php -r "unlink('/composer-setup.php');"
# END Composer Install

# START PHP Configuration
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

RUN sed -e 's/;error_log = php_errors.log/error_log = \/var\/log\/apache2\/php_error.log/' -i /usr/local/etc/php/php.ini

# END PHP Configuration

# START Install Redis Support For PHP
RUN apt-get update && apt-get install -y --no-install-recommends \
    --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# END Install Redis Support For PHP

# START Configure Apache2
RUN a2enmod rewrite
RUN a2enmod ssl

RUN mkdir /etc/apache2/ssl
COPY certs /etc/apache2/ssl

COPY default-sites /etc/apache2/sites-available
RUN a2ensite default-ssl
# END Configure Apache2

EXPOSE 80
EXPOSE 443