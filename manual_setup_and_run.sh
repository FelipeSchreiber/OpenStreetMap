#! /bin/bash
region=south-america/brazil
port="7070:70"
vol=$(docker volume inspect osm-data)
if [[ $?=1 ]] then;
    docker volume create osm-data
fi
if ! [ -f *osm.pbf ]; then
    ./download_data.sh -r "$region"
fi
./setup.sh 
./launch_tiles_server.sh -p "$port"