#!/bin/sh
PASSWORD=`cat .password`
PWD=`pwd`
BASE=`basename $PWD`
DOCKER_PGSQL=${BASE}_pgsql_1
DOCKER_WEB=${BASE}_web_1
PGDB=humanitarianresp

# Install site
docker exec -it $DOCKER_WEB sh -c "cd /var/www/html; drush -y site-install --db-url=pgsql://$PGDB:$PGDB@pgsql:5432/$PGDB --db-prefix=drupal."

# Tweak the site
docker exec -it $DOCKER_WEB mkdir -p /var/www/html/sites/default/private/temp
docker exec -it $DOCKER_WEB chown -R apache:apache /var/www/html/sites/default/private
docker exec -it $DOCKER_WEB chown -R apache:apache /var/www/html/sites/default/files
# TODO search for a environment based variable values.
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/default; drush vset file_public_path sites/default/files; drush vset file_private_path sites/default/private; drush vset file_temporary_path sites/default/private/temp; drush vset hid_auth_login_enabled TRUE; drush vset stage_file_proxy_origin http://www.humanitarianresponse.info;drush vset stage_file_proxy_origin_dir sites/www.humanitarianresponse.info/files'
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/default; drush -y dis securelogin varnish memcache advagg; drush -y en stage_file_proxy;'
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/default; drush vset smtp_host mailhog; drush vset smtp_port 1025'
cp solr.php ./code/sites/default
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/default; drush scr solr.php; drush sapi-c; drush sapi-i default_node_index'
