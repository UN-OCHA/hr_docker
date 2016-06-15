# If you want xdebug installed in the FPM container, you can do so
# by making docker-compose use this Dockerfile for the fpm container
# instead of using the alpine-base-php-fpm container outright.
#
# To do so, add a comment # to the `image` entry fo the fpm container
# definition in docker-compse.yml and remove it from the `build` entry
# for the same definition. Tadah!

FROM unocha/alpine-base-php-fpm:3.4

RUN apk add \
    --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
      php-xdebug && \
    rm -rf /var/cache/apk/*

RUN echo zend_extension=xdebug.so > /etc/php5/conf.d/xdebug.ini; \
    echo xdebug.remote_enable=on >> /etc/php5/conf.d/xdebug.ini; \
    echo xdebug.remote_connect_back=on >> /etc/php5/conf.d/xdebug.ini; \
    echo xdebug.remote_port=9000 >> /etc/php5/conf.d/xdebug.ini; \
    echo xdebug.remote_handler=dbgp >> /etc/php5/conf.d/xdebug.ini; \
    echo xdebug.remote_log=/tmp/php-xdebug.log >> /etc/php5/conf.d/xdebug.ini; \
    echo xdebug.max_nesting_level=10000 >> /etc/php5/conf.d/xdebug.ini;
