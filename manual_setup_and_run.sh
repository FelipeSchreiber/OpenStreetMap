#! /bin/bash

while getopts r:p: flag
do
    case "${flag}" in
        r) region=${OPTARG};;
        p) port=${OPTARG};;
    esac
done

if [ -z "$region" ]; then
    echo "--- setting default \$region to south-america/brazil"
    region="${region:-south-america/brazil}"
fi

if [ -z "$port" ]; then
    echo "--- setting default \$port to 7070:70"
    port="${port:-7070:70}"
fi

vol=$(docker volume inspect osm-data)
if [[ $?=1 ]]; then
    docker volume create osm-data
fi
if ! [ -f *osm.pbf ]; then
    ./download_data.sh -r "$region"
fi
./setup.sh 
./launch_tiles_server.sh -p "$port"