#! /bin/bash
rm -f *osm.pbf*
rm -f *poly*
docker ps -a --filter ancestor='overv/openstreetmap-tile-server' --format="{{.ID}}" | xargs docker stop | xargs docker rm
docker container prune -f
docker volume rm osm-data
docker images | awk  '$1 == "overv/openstreetmap-tile-server" {print $3}' | xargs docker image rm