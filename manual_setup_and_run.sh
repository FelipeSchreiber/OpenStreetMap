#! /bin/bash
: '
https://switch2osm.org/serving-tiles/using-a-docker-container/
https://github.com/Overv/openstreetmap-tile-server/tree/master
'

download_from_container=false
while getopts r:p:d flag
do
    case "${flag}" in
        r) region=${OPTARG};;
        p) port=${OPTARG};;
        d) download_from_container=true;;
    esac
done

if [ -z "$region" ]; then
    echo "--- setting default \$region to south-america/brazil"
    region="${region:-south-america/brazil}"
fi

if [ -z "$port" ]; then
    echo "--- setting default \$port to 7070"
    port="${port:-7070}"
fi

vol=$(docker volume inspect osm-data)
if [[ $?=1 ]]; then
    docker volume create osm-data
fi

if $download_from_container; then
    ./download_inside_container.sh -r "$region"
else
    if ! [ -f *osm.pbf ]; then
        ./download_data.sh -r "$region"
    fi
    ./setup.sh 
fi
echo "################ FINISHED SETUP ################"
./launch_tiles_server.sh -p "$port:80"