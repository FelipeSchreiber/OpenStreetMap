#! /bin/bash
docker run \
    -e DOWNLOAD_PBF=https://download.geofabrik.de/south-america/brazil-latest.osm.pbf \
    -e DOWNLOAD_POLY=https://download.geofabrik.de/south-america/brazil.poly \
    -v osm-data:/data/database/ \
    overv/openstreetmap-tile-server \
    import