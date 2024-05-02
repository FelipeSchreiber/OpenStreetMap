#! /bin/bash
while getopts r:p: flag
do
    case "${flag}" in
        r) region=${OPTARG};;
        p) port=${OPTARG};;
    esac
done

if [ -z "$region" ]; then
    echo "--- setting default \$region to europe/malta"
    region="${region:-europe/malta}"
fi

if [ -z "$port" ]; then
    echo "--- setting default \$port to 8080:80"
    port="${port:-8080:80}"
fi

docker volume create osm-data
docker run \
    -e DOWNLOAD_PBF=https://download.geofabrik.de/${region}-latest.osm.pbf \
    -e DOWNLOAD_POLY=https://download.geofabrik.de/${region}.poly \
    -v osm-data:/data/database/ \
    overv/openstreetmap-tile-server \
    import
echo "################ FINISHED SETUP ################"
docker run \
    -p ${port} \
    -v osm-data:/data/database/ \
    -d overv/openstreetmap-tile-server \
    run