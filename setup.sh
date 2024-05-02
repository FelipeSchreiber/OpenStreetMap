#! /bin/bash
osm_pbf_file="$(pwd)/$(find . -type f -name "*osm.pbf" -printf "%f\n")"
echo "$osm_pbf_file"
docker run \
    -v ${osm_pbf_file}:/data/region.osm.pbf \
    -v osm-data:/data/database/ \
    overv/openstreetmap-tile-server \
    import