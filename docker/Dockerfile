FROM wordpress:php8.3-apache

RUN a2enmod rewrite

# Ship our PHP (themes, plugins, must-use plugins) immutably inside the image.
COPY wordpress/wp-content/themes/     /var/www/html/wp-content/themes/
COPY wordpress/wp-content/plugins/    /var/www/html/wp-content/plugins/
COPY wordpress/wp-content/mu-plugins/ /var/www/html/wp-content/mu-plugins/

# Extra config is loaded from wp-config.php through WORDPRESS_CONFIG_EXTRA.
COPY wordpress/config/wp-config-extra.php /var/www/html/wp-config-extra.php
ENV WORDPRESS_CONFIG_EXTRA="require_once '/var/www/html/wp-config-extra.php';"
