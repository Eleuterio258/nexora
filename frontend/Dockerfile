FROM php:8.3-apache

RUN a2enmod rewrite headers expires

# Allow project-level Apache rules.
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Dompdf requires mbstring; zip is needed by Composer to extract packages.
RUN docker-php-ext-install mbstring \
    && apt-get update && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . /var/www/html/

RUN cd /var/www/html && composer install --no-dev --optimize-autoloader --no-interaction

RUN mkdir -p /var/www/html/uploads/cv \
    && chown -R www-data:www-data /var/www/html/uploads \
    && chmod -R 750 /var/www/html/uploads

RUN chown -R www-data:www-data /var/www/html/config \
    && chmod 750 /var/www/html/config \
    && chmod 640 /var/www/html/config/*.php \
    && chmod 750 /var/www/html/sql

EXPOSE 80
