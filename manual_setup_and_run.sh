#! /bin/bash
region=south-america/brazil
port="7070:70"
docker volume create osm-data
./download_data.sh -r "$region"
./setup.sh 
./launch_tiles_server.sh -p "$port"