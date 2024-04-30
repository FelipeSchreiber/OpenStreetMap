#!/bin/bash
# https://switch2osm.org/serving-tiles/using-a-docker-container/
(cd;
wget https://download.geofabrik.de/south-america/brazil-latest.osm.pbf;
docker volume create osm-data
)