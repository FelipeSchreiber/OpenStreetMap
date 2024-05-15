#! /bin/bash
while getopts p: flag
do
    case "${flag}" in
        p) port=${OPTARG};;
    esac
done

if [ -z "$port" ]; then
    echo "--- setting default \$port to 7070:70"
    port="${port:-7070:70}"
fi
echo "$port"
docker run \
    -p "$port" \
    -e THREADS=8 \
    -v osm-data:/data/database/ \
    -d overv/openstreetmap-tile-server \
    run
    # --shm-size="4g" \