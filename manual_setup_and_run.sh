#! /bin/bash
region=south-america/brazil
port="7070:70"
docker volume create osm-data
if ! [ -f *osm.pbf ]; then
    ./download_data.sh -r "$region"
fi
./setup.sh 
./launch_tiles_server.sh -p "$port"