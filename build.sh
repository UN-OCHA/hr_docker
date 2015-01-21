#!/bin/sh
PASSWORD=`cat .password`

# Grab latest code snapshot
wget --user=hrinfo --password=$PASSWORD http://snapshots.humanitarianresponse.info/humanitarianresponse-7.x-2.x-snapshot.tar.gz -O code.tar.gz

# Untar it into ./code
tar -zxvf code.tar.gz -C code

# Create user and database
docker exec -it hrdocker_pgsql_1 sh -c "exec psql -h \"$POSTGRES_PORT_5432_TCP_ADDR\" -p \"$POSTGRES_PORT_5432_TCP_PORT\" -U postgres -c \"CREATE USER hrinfo WITH PASSWORD 'hrinfo'\""
docker exec -it hrdocker_pgsql_1 sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -c "CREATE DATABASE hrinfo"'
docker exec -it hrdocker_pgsql_1 sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE hrinfo TO hrinfo"'

# Allow connections to postgresql from 172.17.42.0/24
# TODO This could probably be avoided by putting the configuration directly in the container
docker exec -it hrdocker_pgsql_1 sh -c 'echo -e "host\tall\t\tall\t172.17.42.0/24\tmd5" >> /var/lib/pgsql/9.3/config/pg_hba.conf'
docker exec -it hrdocker_pgsql_1 /etc/init.d/postgresql-9.3 reload

# Install site
docker exec -it hrdocker_web_1 sh -c 'cd /var/www/html; drush -y site-install --sites-subdir=www.hrinfo.vm --db-url=pgsql://hrinfo:hrinfo@pgsql.hrinfo.vm:5432/hrinfo'

# Get latest database snapshot and install it
cp hrinfo_snapshot.sh ./data/hrinfo/pgsql
docker exec -it hrdocker_pgsql_1 sh /var/lib/pgsql/9.3/data/hrinfo_snapshot.sh $PASSWORD

# Tweak the site
docker exec -it hrdocker_web_1 mkdir -p /var/www/html/sites/www.hrinfo.vm/private/temp
docker exec -it hrdocker_web_1 chown -R apache:apache /var/www/html/sites/www.hrinfo.vm/private/temp
docker exec -it hrdocker_web_1 chown -R apache:apache /var/www/html/sites/www.hrinfo.vm/files
docker exec -it hrdocker_web_1 sh -c 'cd /var/www/html/sites/www.hrinfo.vm; drush vset file_public_path sites/www.hrinfo.vm/files; drush vset file_private_path sites/www.hrinfo.vm/private; drush vset file_temporary_path sites/www.hrinfo.vm/private/temp; drush -y dis securelogin varnish memcache advagg; drush dl stage_file_proxy; drush -y en stage_file_proxy;drush vset stage_file_proxy_origin http://www.humanitarianresponse.info;drush vset stage_file_proxy_origin_dir sites/www.humanitarianresponse.info/files'
cp solr.php ./code/sites/www.hrinfo.vm
docker exec -it hrdocker_web_1 sh -c 'cd /var/www/html/sites/www.hrinfo.vm; drush scr solr.php; drush sapi-c; drush sapi-i default_node_index'
