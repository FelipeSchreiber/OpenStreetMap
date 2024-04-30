#! /bin/bash
docker run -p 7070:70 -v osm-data:/data/database -d overv/openstreetmap-tile-server run