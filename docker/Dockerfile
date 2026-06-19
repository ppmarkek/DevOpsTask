FROM wordpress:latest

RUN a2enmod rewrite

COPY wordpress/wp-content/themes/   /var/www/html/wp-content/themes/
COPY wordpress/wp-content/plugins/  /var/www/html/wp-content/plugins/
COPY wordpress/wp-content/mu-plugins/   /var/www/html/wp-content/mu-plugins/