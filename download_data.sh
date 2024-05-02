#!/bin/bash
# https://switch2osm.org/serving-tiles/using-a-docker-container/
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

wget https://download.geofabrik.de/${region}-latest.osm.pbf
wget https://download.geofabrik.de/${region}.poly