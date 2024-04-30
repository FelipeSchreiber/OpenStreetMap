#! /bin/bash
docker ps -a --filter ancestor='overv/openstreetmap-tile-server' --format="{{.ID}}" | xargs docker stop | xargs docker rm
docker volume rm osm-data
docker volume create osm-data
