FROM php:8.3-apache

RUN a2enmod rewrite headers expires

# Allow project-level Apache rules.
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

COPY . /var/www/html/

RUN mkdir -p /var/www/html/uploads/cv \
    && chown -R www-data:www-data /var/www/html/uploads \
    && chmod -R 750 /var/www/html/uploads

RUN chown -R www-data:www-data /var/www/html/config \
    && chmod 750 /var/www/html/config \
    && chmod 640 /var/www/html/config/*.php \
    && chmod 750 /var/www/html/sql

EXPOSE 80
