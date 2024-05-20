#! /bin/bash
source ./usefull_sed_lib.sh
db_port="54320:5432"
BEGIN=$(cat <<EOF
  db:
    build:
      context: .
      dockerfile: docker/postgres/Dockerfile
    ports:
      -
EOF
)
END=$(cat <<EOF
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
      POSTGRES_DB: openstreetmap
    volumes:
      # Mount the Postgres data directory so it persists between runs
      - db-data:/var/lib/postgresql/data

EOF
)
BEGIN="$(escape_slashes "$BEGIN")"
END="$(escape_slashes "$END")"
replace_between_START_END_REPLACE_FILENAME "$BEGIN" "$END" "$db_port" 'openstreetmap-website/docker-compose.yml' 