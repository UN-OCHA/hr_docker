#!/bin/sh

POSTGIS_DIR=/usr/pgsql-9.3/share/contrib/postgis-2.1
PGDB=hrinfo
PGHOST=pgsql.hrinfo.vm
PGUSER=postgres
PASSWORD=$1

# Get the latest database snapshot
wget --user=hrinfo --password=$PASSWORD http://snapshots.humanitarianresponse.info/www.humanitarianresponse.info.pg_restore -O /tmp/www.humanitarianresponse.info.pg_restore

# Recreate database
echo "Recreating database"
psql -U $PGUSER -c "DROP DATABASE $PGDB;"
psql -U $PGUSER -c "CREATE DATABASE $PGDB OWNER $PGDB ENCODING 'UTF8';"

echo "Installing postgis"
psql -U $PGUSER -d $PGDB -f $POSTGIS_DIR/postgis.sql
psql -U $PGUSER -d $PGDB -f $POSTGIS_DIR/spatial_ref_sys.sql
psql -U $PGUSER -d $PGDB -f $POSTGIS_DIR/postgis_comments.sql
psql -U $PGUSER -d $PGDB -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
psql -U $PGUSER -d $PGDB -c "GRANT ALL ON geometry_columns TO $PGDB;"

echo "Restoring from backup"
$POSTGIS_DIR/postgis_restore.pl /tmp/www.humanitarianresponse.info.pg_restore > /tmp/www.humanitarianresponse.info.postgis_restore
psql -U $PGUSER $PGDB < /tmp/www.humanitarianresponse.info.postgis_restore

echo "Granting permission on all tables to $PGDB"
psql -At -U $PGUSER -d $PGDB -c "SELECT 'GRANT ALL ON '||tablename||' TO $PGDB;' FROM pg_tables WHERE schemaname='public';" | psql -U $PGUSER -d $PGDB
psql -At -U $PGUSER -d $PGDB -c "SELECT 'GRANT ALL ON '||c.relname||' TO $PGDB;' FROM pg_class c JOIN pg_namespace n ON (n.oid=c.relnamespace) WHERE c.relkind='S' AND n.nspname='public';" | psql -U $PGUSER -d $PGDB


