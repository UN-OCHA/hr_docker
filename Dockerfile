FROM ubuntu:14.04

# Install apache and php
RUN apt-get update && \
    apt-get -y install apache2 libapache2-mod-php5 php5-gd php5-mysql php5-pgsql php5-xdebug php5-curl drush vim

# Allow overrides
ADD conf/apache.conf /etc/apache2/sites-enabled/000-default.conf
ADD conf/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
ADD conf/php.ini /etc/php5/apache2/php.ini

# Enable apache modules
RUN a2enmod rewrite headers ssl

# Enable SSL virtual host
RUN a2ensite default-ssl.conf

VOLUME ["/var/www/html"]

EXPOSE 80 443
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]

