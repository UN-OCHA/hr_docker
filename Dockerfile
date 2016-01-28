FROM unocha/base

ADD root /

ENV TERM vt100

# Webserver install
RUN yum -y install http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm && \
    yum -y install http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-14.ius.centos6.noarch.rpm && \
    yum -y update
RUN yum -y install postgresql93 mysql httpd sudo rsync git postfix unzip patch python-pip shibboleth
RUN yum -y install proj-4.8.0 geos-3.3.3 gdal-1.8.1
RUN yum -y install --enablerepo=iusarchive php53u php53u-mysql php53u-cli php53u-gd php53u-process php53u-pear php53u-mbstring php53u-mcrypt php53u-devel php53u-process php53u-gd php53u-xml php53u-pdo php53u-mysql php53u-imap php53u-soap php53u-pecl-apc php53u-pecl-xhprof php53u-pgsql php53u-pecl-memcache php53u-pecl-geoip php53u-pecl-xdebug
RUN yum -y install /opt/rpms/ImageMagick-6.8.9-10.x86_64.rpm /opt/rpms/ImageMagick-libs-6.8.9-10.x86_64.rpm /opt/rpms/ghostscript-9.14-7.el6.x86_64.rpm
RUN pip install --upgrade pip
RUN pip install meld3==1.0.1 supervisor supervisor-stdout

# Set up PHP date handling
RUN cat /usr/share/zoneinfo/US/Eastern > /etc/localtime

# Setup Drush using Composer
RUN echo "allow_url_fopen = On" >> /etc/php.ini
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
ENV PATH "/root/.composer/vendor/bin:$PATH"
RUN composer global require drush/drush:7.1.0

# Install PECL packages
RUN yum -y install @"Development Tools"
RUN pecl install uploadprogress XHProf-0.9.4
RUN yum -y install mod_ssl cronolog

RUN usermod -u 1000 apache

# Allow overrides
COPY config/hrinfo/etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf
COPY config/hrinfo/etc/httpd/conf/magic /etc/httpd/conf/magic
COPY config/hrinfo/etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf
COPY config/hrinfo/etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf
COPY conf/php.ini /etc/php.ini
COPY config/hrinfo/etc/php.d/uploadprogress.ini /etc/php.d/uploadprogress.ini
COPY config/hrinfo/etc/supervisord.d/supervisord.conf /etc/supervisord.conf

# Configure xdebug
RUN echo xdebug.remote_enable=on >> /etc/php.d/xdebug.ini; \
    echo xdebug.remote_connect_back=on >> /etc/php.d/xdebug.ini; \
    echo xdebug.remote_port=9000 >> /etc/php.d/xdebug.ini; \
    echo xdebug.remote_handler=dbgp >> /etc/php.d/xdebug.ini; \
    echo xdebug.remote_log=/tmp/php5-xdebug.log >> /etc/php.d/xdebug.ini; \
    echo xdebug.max_nesting_level=10000 >> /etc/php.d/xdebug.ini;

VOLUME ["/var/www/html"]

EXPOSE 80 443 1080
CMD ["/usr/bin/supervisord"]
