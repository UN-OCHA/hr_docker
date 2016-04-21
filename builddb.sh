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

# Get latest database snapshot and install it
cp hrinfo_snapshot.sh ./data/hrinfo/pgsql
docker exec -it $DOCKER_PGSQL sh /var/lib/pgsql/9.3/data/hrinfo_snapshot.sh $PASSWORD
