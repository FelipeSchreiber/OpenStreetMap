#! /bin/bash
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
echo "#################### IMPORTING $region ####################"
docker run \
    -e DOWNLOAD_PBF=https://download.geofabrik.de/${region}-latest.osm.pbf \
    -e DOWNLOAD_POLY=https://download.geofabrik.de/${region}.poly \
    -v osm-data:/data/database/ \
    overv/openstreetmap-tile-server \
    import