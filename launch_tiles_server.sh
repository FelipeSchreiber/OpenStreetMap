#! /bin/bash
while getopts p: flag
do
    case "${flag}" in
        p) port=${OPTARG};;
    esac
done

if [ -z "$port" ]; then
    echo "--- setting default \$port to 8080:80"
    port="${port:-8080:80}"
fi

docker run \
    -p ${port} \
    -v osm-data:/data/database/ \
    -d overv/openstreetmap-tile-server \
    run