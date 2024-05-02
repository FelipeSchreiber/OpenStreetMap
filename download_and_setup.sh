#! /bin/bash
docker volume create osm-data
docker run \
    -e DOWNLOAD_PBF=https://download.geofabrik.de/europe/malta-latest.osm.pbf \
    -e DOWNLOAD_POLY=https://download.geofabrik.de/europe/malta.poly \
    -v osm-data:/data/database/ \
    overv/openstreetmap-tile-server \
    import
echo "################ FINISHED SETUP ################"
docker run \
    -p 8080:80 \
    -v osm-data:/data/database/ \
    -d overv/openstreetmap-tile-server \
    run