FROM unocha/base
MAINTAINER Steven Merrill <steven.merrill@gmail.com>

ENV TERM vt100

# Install Postgres, MySQL, build tools, PHP, and supervisord.
RUN yum -y install http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm && \
    yum -y update && \
    yum -y install postgresql93 mysql httpd sudo rsync git postfix unzip patch python-pip \
      php php-mysql php-cli php-gd php-process php-pear php-mbstring php-mcrypt php-devel php-process php-gd php-xml php-pdo php-mysql php-imap php-soap php-pecl-apc php-pecl-xhprof php-pgsql && \
    pip install supervisor supervisor-stdout

# Set up PHP date handling and Drush 5.10.
RUN echo 'date.timezone = "America/New_York"' >> /etc/php.ini && \
    cat /usr/share/zoneinfo/US/Eastern > /etc/localtime && \
    pear channel-discover pear.drush.org && \
    pear install drush/drush-5.10.0.0 && \
    pear install Console_Table

# Raise PHP memory_limit to 512 M
RUN sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php.ini

VOLUME ["/etc/httpd/conf","/etc/httpd/conf.d","/etc/supervisord.d","/var/www/html"]

EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.d/supervisord.conf"]

