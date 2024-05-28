#! /bin/bash
: '
https://switch2osm.org/serving-tiles/using-a-docker-container/
https://github.com/Overv/openstreetmap-tile-server/tree/master
'
git clone https://github.com/FelipeSchreiber/openstreetmap-tile-server.git
rm -f openstreetmap-tile-server/leaflet-demo.html
cp leaflet-demo.html ./openstreetmap-tile-server
cp power_tower.png ./openstreetmap-tile-server
cd openstreetmap-tile-server
docker build ./ -t overv/openstreetmap-tile-server
cd ..
download_from_container=false
while getopts r:p:d flag
do
    case "${flag}" in
        r) region=${OPTARG};;
        p) port=${OPTARG};;
        d) download_from_container=true;;
    esac
done

if [ -z "$region" ]; then
    echo "--- setting default \$region to south-america/brazil"
    region="${region:-south-america/brazil}"
fi

if [ -z "$port" ]; then
    echo "--- setting default \$port to 7070"
    port="${port:-7070}"
fi

vol=$(docker volume inspect osm-data)
if [[ $?=1 ]]; then
    docker volume create osm-data
fi

if $download_from_container; then
    ./download_inside_container.sh -r "$region"
else
    if ! [ -f *osm.pbf ]; then
        ./download_data.sh -r "$region"
    fi
    ./setup.sh 
fi
echo "################ FINISHED SETUP ################"
./launch_tiles_server.sh -p "$port:80"