#!/bin/sh

POSTGIS_DIR=/usr/pgsql-9.3/share/contrib/postgis-2.1
PGDB=humanitarianresp
PGHOST=pgsql.hrinfo.vm
PGUSER=postgres
PASSWORD=$1

# Get the latest database snapshot
wget --user=hrinfo --password=$PASSWORD http://snapshots.humanitarianresponse.info/www.humanitarianresponse.info.pg_restore -O /tmp/www.humanitarianresponse.info.pg_restore

# Recreate database
echo "Recreating database"
psql -U $PGUSER -c "DROP DATABASE $PGDB;"
psql -U $PGUSER -c "CREATE DATABASE $PGDB OWNER $PGDB ENCODING 'UTF8';"
psql -U $PGUSER -d $PGDB -c "CREATE SCHEMA drupal AUTHORIZATION $PGDB;"

echo "Installing postgis"
psql -U $PGUSER -d $PGDB -f $POSTGIS_DIR/postgis.sql
psql -U $PGUSER -d $PGDB -f $POSTGIS_DIR/spatial_ref_sys.sql
psql -U $PGUSER -d $PGDB -f $POSTGIS_DIR/postgis_comments.sql
psql -U $PGUSER -d $PGDB -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
psql -U $PGUSER -d $PGDB -c "GRANT ALL ON geometry_columns TO $PGDB;"

echo "Restoring from backup"
$POSTGIS_DIR/postgis_restore.pl /tmp/www.humanitarianresponse.info.pg_restore > /tmp/www.humanitarianresponse.info.postgis_restore
psql -U $PGUSER $PGDB < /tmp/www.humanitarianresponse.info.postgis_restore

psql -U $PGUSER -c 'ALTER USER $PGDB SET search_path = "$user",public,drupal;'

echo "Granting permission on all tables to $PGDB"
psql -At -U $PGUSER -d $PGDB -c "SELECT 'GRANT ALL ON '||tablename||' TO $PGDB;' FROM pg_tables WHERE schemaname='public' OR schemaname = 'drupal';" | psql -U $PGUSER -d $PGDB
psql -At -U $PGUSER -d $PGDB -c "SELECT 'GRANT ALL ON '||c.relname||' TO $PGDB;' FROM pg_class c JOIN pg_namespace n ON (n.oid=c.relnamespace) WHERE c.relkind='S' AND (n.nspname='public' OR n.nspname = 'drupal');" | psql -U $PGUSER -d $PGDB

echo "Changing table owners to $PGDB"
for tbl in `psql -U postgres -qAt -c "select tablename from pg_tables where schemaname = 'public';" $PGDB` ; do  psql -U postgres -c "alter table $tbl owner to $PGDB" $PGDB ; done
for tbl in `psql -U postgres -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'public';" $PGDB` ; do  psql -U postgres -c "alter table $tbl owner to $PGDB" $PGDB ; done
for tbl in `psql -U postgres -qAt -c "select table_name from information_schema.views where table_schema = 'public';" $PGDB` ; do  psql -U postgres -c "alter table $tbl owner to $PGDB" $PGDB ; done

for tbl in `psql -U postgres -qAt -c "select tablename from pg_tables where schemaname = 'drupal';" $PGDB` ; do  psql -U postgres -c "alter table drupal.$tbl owner to $PGDB" $PGDB ; done
for tbl in `psql -U postgres -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'drupal';" $PGDB` ; do  psql -U postgres -c "alter table drupal.$tbl owner to $PGDB" $PGDB ; done
for tbl in `psql -U postgres -qAt -c "select table_name from information_schema.views where table_schema = 'drupal';" $PGDB` ; do  psql -U postgres -c "alter table drupal.$tbl owner to $PGDB" $PGDB ; done
