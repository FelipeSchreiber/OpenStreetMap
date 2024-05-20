#! /bin/bash
: '
Load the full openstreetmap website
https://github.com/openstreetmap/openstreetmap-website/blob/master/DOCKER.md
'
source ./usefull_sed_lib.sh
while getopts r: flag
do
    case "${flag}" in
        r) region=${OPTARG};;
    esac
done

if [ -z "$region" ]; then
    echo "--- setting default \$region to europe/malta"
    region="${region:-europe/malta}"
fi

if ! [ -d "openstreetmap-website" ]; then
    git clone https://github.com/openstreetmap/openstreetmap-website.git

fi
cd openstreetmap-website
cp config/example.storage.yml config/storage.yml
cp config/docker.database.yml config/database.yml
touch config/settings.local.yml
docker compose build
docker compose up -d

docker compose run --rm web bundle exec rails db:migrate
docker compose run --rm web bundle exec rails db:test:prepare
docker compose run --rm web bundle exec rails test:all

if ! [ -f *osm.pbf ]; then
    wget https://download.geofabrik.de/${region}-latest.osm.pbf
fi

osm_pbf_file="$(find . -type f -name "*osm.pbf" -printf "%f\n")"
echo "$osm_pbf_file"
docker compose run --rm web osmosis \
    -verbose    \
    --read-pbf $osm_pbf_file \
    --log-progress \
    --write-apidb \
        host="db" \
        database="openstreetmap" \
        user="openstreetmap" \
        validateSchemaVersion="no"