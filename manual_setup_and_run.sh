#! /bin/bash
docker volume create osm-data
./download_malta_data.sh
./setup.sh
./launch_tiles_server.sh