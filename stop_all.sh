#! /bin/bash
docker ps -a --filter ancestor='overv/openstreetmap-tile-server' --format="{{.ID}}" | xargs docker stop | xargs docker image rm
docker container prune -f
docker volume rm osm-data