#! /bin/bash
osm_pbf_file="$(pwd)/$(find . -type f -name "*osm.pbf" -printf "%f\n")"
poly_file="$(pwd)/$(find . -type f -name "*.poly" -printf "%f\n")"
docker run \
    -v ${osm_pbf_file}:/data/region.osm.pbf \
    -v ${poly_file}:/data/region.poly \
    -v osm-data:/data/database/ \
    overv/openstreetmap-tile-server \
    import