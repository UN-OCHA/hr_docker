#!/bin/sh
PASSWORD=`cat .password`
PWD=`pwd`
BASE=`basename $PWD`
DOCKER_PGSQL=${BASE}_pgsql_1
DOCKER_WEB=${BASE}_web_1
PGDB=humanitarianresp

# Create user and database
docker exec -it $DOCKER_PGSQL psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -c "CREATE USER $PGDB WITH PASSWORD '$PGDB'"
docker exec -it $DOCKER_PGSQL psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -c "CREATE DATABASE $PGDB"
docker exec -it $DOCKER_PGSQL psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $PGDB TO $PGDB"
docker exec -it $DOCKER_PGSQL psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -d $PGDB -c "CREATE SCHEMA drupal AUTHORIZATION $PGDB"

# Allow connections to postgresql from 172.17.42.0/24
# TODO This could probably be avoided by putting the configuration directly in the container
docker exec -it $DOCKER_PGSQL sh -c 'echo -e "host\tall\t\tall\t172.17.42.0/24\tmd5" >> /var/lib/pgsql/9.3/config/pg_hba.conf'
docker exec -it $DOCKER_PGSQL /etc/init.d/postgresql-9.3 reload

# Install site
docker exec -it $DOCKER_WEB mkdir /var/www/html/sites/www.hrinfo.vm
docker exec -it $DOCKER_WEB sh -c "cd /var/www/html; drush -y site-install --sites-subdir=www.hrinfo.vm --db-url=pgsql://$PGDB:$PGDB@pgsql:5432/$PGDB --db-prefix=drupal."

# Get latest database snapshot and install it
cp hrinfo_snapshot.sh ./data/hrinfo/pgsql
docker exec -it $DOCKER_PGSQL sh /var/lib/pgsql/9.3/data/hrinfo_snapshot.sh $PASSWORD

# Tweak the site
docker exec -it $DOCKER_WEB mkdir -p /var/www/html/sites/www.hrinfo.vm/private/temp
docker exec -it $DOCKER_WEB chown -R apache:apache /var/www/html/sites/www.hrinfo.vm/private/temp
docker exec -it $DOCKER_WEB chown -R apache:apache /var/www/html/sites/www.hrinfo.vm/files
# TODO search for a environment based variable values.
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/www.hrinfo.vm; drush vset file_public_path sites/www.hrinfo.vm/files; drush vset file_private_path sites/www.hrinfo.vm/private; drush vset file_temporary_path sites/www.hrinfo.vm/private/temp; drush vset hid_auth_login_enabled TRUE; drush vset stage_file_proxy_origin http://www.humanitarianresponse.info;drush vset stage_file_proxy_origin_dir sites/www.humanitarianresponse.info/files'
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/www.hrinfo.vm; drush -y dis securelogin varnish memcache advagg; drush -y en stage_file_proxy;'
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/www.hrinfo.vm; drush vset smtp_host mailhog; drush vset smtp_port 1025'
cp solr.php ./code/sites/www.hrinfo.vm
docker exec -it $DOCKER_WEB sh -c 'cd /var/www/html/sites/www.hrinfo.vm; drush scr solr.php; drush sapi-c; drush sapi-i default_node_index'
