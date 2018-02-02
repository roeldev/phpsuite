FROM php:7.1.14-cli
LABEL vendor="phpsuite" version="0.1"

ENV COMPOSER_ALLOW_SUPERUSER=1

# Install required utilities
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        apt-utils \
        git \
        unzip

# Install Composer - https://getcomposer.org/download/
RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer

# Install Xdebug - https://xdebug.org/docs/install
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Clean temporary files
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy custom and/or required files
COPY php.ini /usr/local/etc/php/

# Install tools using composer
RUN composer global require \
    --no-plugins \
    --no-scripts \
    --no-suggest \
    --optimize-autoloader \
    "hirak/prestissimo" \
    "phpmd/phpmd ^2.6" \
    "phpstan/phpstan ^0.9" \
    "roeldev/phpcs-ruleset ^1.0" \
    "squizlabs/php_codesniffer ^3.1"

ENV PATH /root/.composer/vendor/bin:$PATH
