#! /bin/bash
git clone https://github.com/Overv/openstreetmap-tile-server.git
mv openstreetmap-tile-server Openstreetmap
#rm -rf openstreetmap-tile-server-master
cd Openstreetmap
mkdir Data
cd Data
wget http://download.geofabrik.de/europe/malta-latest.osm.pbf
wget http://download.geofabrik.de/europe/malta.poly
mv *.poly data.poly
cd ..
wget https://leafletjs-cdn.s3.amazonaws.com/content/leaflet/v1.9.4/leaflet.zip
unzip leaflet*
rm -f leaflet-demo.html
leaflet_demo=$(cat <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>Custom Tile Server</title><meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"><link rel="stylesheet" href="leaflet.css"  crossorigin=""/>
<script src="leaflet.js"  crossorigin=""></script><style>
   html, body, #map {
   width: 100%;
   height: 100%;
   margin: 0;
   padding: 0;
   }
</style>
</head><body>
        <div id="map"></div><script>
var map = L.map('map').setView([0, 0], 3);
L.tileLayer('/tile/{z}/{x}/{y}.png', {
maxZoom: 18,
attribution: 'Map data &copy; <a   href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
id: 'base'
}).addTo(map);
</script></body>
</html>
EOF
)

echo "$leaflet_demo"| tee leaflet-demo.html

dependencies=$(cat <<EOF
#!/bin/bash

apt-get update \
  && apt-get install wget gnupg2 lsb-core -y \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo "deb [ trusted=yes ] http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list \
  && apt-get update \
  && apt-get install -y apt-transport-https ca-certificates \
  && apt-get install -y --no-install-recommends --allow-unauthenticated \
  apache2 \
  apache2-dev \
  autoconf \
  build-essential \
  bzip2 \
  cmake \
  fonts-noto-cjk \
  fonts-noto-hinted \
  fonts-noto-unhinted \
  clang \
  gcc \
  gdal-bin \
  make \
  git-core \
  libagg-dev \
  libboost-all-dev \
  libbz2-dev \
  libcairo-dev \
  libcairomm-1.0-dev \
  libexpat1-dev \
  libfreetype6-dev \
  libgdal-dev \
  libgeos++-dev \
  libgeos-dev \
  libgeotiff-epsg \
  libicu-dev \
  liblua5.3-dev \
  libmapnik-dev \
  libpq-dev \
  libproj-dev \
  libprotobuf-c0-dev \
  libtiff5-dev \
  libtool \
  libxml2-dev \
  lua5.3 \
  make \
  mapnik-utils \
  nodejs \
  npm \
  postgis \
  postgresql-12 \
  postgresql-server-dev-12 \
  postgresql-contrib-12 \
  protobuf-c-compiler \
  python-mapnik \
  sudo \
  tar \
  ttf-unifont \
  unzip \
  wget \
  zlib1g-dev \
  osmosis \
  osmium-tool \
  cron \
  python3-psycopg2 python3-shapely python3-lxml \
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/
EOF
)

echo "$dependencies"| tee dependencies.sh

dockerfile=$(cat <<EOF
# Based on
# https://switch2osm.org/manually-building-a-tile-server-18-04-lts/
# Set up environment
ENV TZ=UTC
ENV AUTOVACUUM=off
ENV UPDATES=disabled
RUN ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime && echo \$TZ > /etc/timezone# Install dependenciesCOPY  ./Openstreetmap/dependencies.sh / 
RUN ["chmod","+x","/dependencies.sh"]
RUN /dependencies.sh# Set up PostGIS
RUN wget http://download.osgeo.org/postgis/source/postgis-3.0.0rc2.tar.gz
RUN tar -xvzf postgis-3.0.0rc2.tar.gz
RUN cd postgis-3.0.0rc2 && ./configure && make && make install# Set up renderer user
RUN adduser --disabled-password --gecos "" renderer
USER renderer# Install latest osm2pgsql
RUN mkdir /home/renderer/src
WORKDIR /home/renderer/src
RUN git clone https://github.com/openstreetmap/osm2pgsql.git
WORKDIR /home/renderer/src/osm2pgsql
RUN mkdir build
WORKDIR /home/renderer/src/osm2pgsql/build
RUN cmake .. \
  && make -j \$(nproc)
USER root
RUN make install
RUN mkdir /nodes \
    && chown renderer:renderer /nodes
USER renderer# Install and test Mapnik
RUN python -c 'import mapnik'# Install mod_tile and renderd
WORKDIR /home/renderer/src
RUN git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git
WORKDIR /home/renderer/src/mod_tile
RUN ./autogen.sh \
  && ./configure \
  && make -j \$(nproc)
USER root
RUN make -j \$(nproc) install \
  && make -j \$(nproc) install-mod_tile \
  && ldconfig
USER renderer# Configure stylesheet
WORKDIR /home/renderer/src
RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git \
 && git -C openstreetmap-carto checkout v4.23.0
WORKDIR /home/renderer/src/openstreetmap-carto
USER root
RUN npm install -g carto@0.18.2
USER renderer
RUN carto project.mml > mapnik.xml# Load shapefiles
USER root
WORKDIR /home/renderer/src/openstreetmap-carto
RUN scripts/get-shapefiles.py# Configure renderd
USER root
RUN sed -i 's/renderaccount/renderer/g' /usr/local/etc/renderd.conf \
  && sed -i 's/hot/tile/g' /usr/local/etc/renderd.conf
USER renderer# Configure Apache
USER root
RUN mkdir /var/lib/mod_tile \
  && chown renderer /var/lib/mod_tile \
  && mkdir /var/run/renderd \
  && chown renderer /var/run/renderd
RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
    && echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
  && a2enconf mod_tile && a2enconf mod_headers
COPY ./Openstreetmap/apache.conf /etc/apache2/sites-available/000-default.conf
COPY  ./Openstreetmap/leaflet-demo.html /var/www/html/index.html
COPY  ./Openstreetmap/leaflet.css  /var/www/html/leaflet.css
COPY  ./Openstreetmap/leaflet.js  /var/www/html/leaflet.js
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
  && ln -sf /dev/stderr /var/log/apache2/error.log# Configure PosgtreSQL
COPY ./Openstreetmap/postgresql.custom.conf.tmpl /etc/postgresql/12/main/
RUN chown -R postgres:postgres /var/lib/postgresql \
  && chown postgres:postgres /etc/postgresql/12/main/postgresql.custom.conf.tmpl \
  && echo "\ninclude 'postgresql.custom.conf'" >> /etc/postgresql/12/main/postgresql.conf
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/12/main/pg_hba.conf \
      && echo "host all all ::/0 md5" >> /etc/postgresql/12/main/pg_hba.conf# copy update scripts
COPY ./Openstreetmap/openstreetmap-tiles-update-expire /usr/bin/
RUN chmod +x /usr/bin/openstreetmap-tiles-update-expire \
    && mkdir /var/log/tiles \
    && chmod a+rw /var/log/tiles \
    && ln -s /home/renderer/src/mod_tile/osmosis-db_replag /usr/bin/osmosis-db_replag \
    && echo "*  *    * * *   renderer    openstreetmap-tiles-update-expire\n" >> /etc/crontab# install trim_osc.py helper script
USER renderer
RUN cd ~/src \
    && git clone https://github.com/zverik/regional \
    && cd regional \
    && git checkout 612fe3e040d8bb70d2ab3b133f3b2cfc6c940520 \
    && chmod u+x ~/src/regional/trim_osc.py# Start running
USER root#search for the data files in Data folder
CMD file_pbf=\$(find Data/  -name "*.osm.pbf" -printf "%f\n")
CMD file_poly=\$(find Data/  -name "*.poly" -printf "%f\n")#move the data files to the container
RUN mkdir /home/renderer/src/Data
COPY  ./Openstreetmap/Data/\$file_pbf   /home/renderer/src/Data/
COPY  ./Openstreetmap/Data/\$file_poly  /var/lib/mod_tile/file_poly/#run script to insert data to the database
COPY  ./Openstreetmap/run.sh /
COPY ./Openstreetmap/indexes.sql /
ENTRYPOINT ["/run.sh"]
CMD []#expose ports
EXPOSE 80 5432
EOF
)

rm -f Dockerfile
echo "$dockerfile" | tee Dockerfile

run_script=$(cat <<EOF
#!/bin/bashset -x
#initaialize variables
#define the number of threads
THREADS=4#enable CORS => CORS=1, disable CORS=> CORS=0
ALLOW_CORS=1#enable or disable autovacuum feature in postgresql
#enable autovacuum=> AUTOVACUUM=on, disable autovacuum => #AUTOVACUUM=offAUTOVACUUM=off#to enable cache assign the value
OSM2PGSQL_EXTRA_ARGS="-C 4096"
#create a docker volume for the databse
sudo docker volume create openstreetmap-datafunction createPostgresConfig() {
  cp /etc/postgresql/12/main/postgresql.custom.conf.tmpl /etc/postgresql/12/main/postgresql.custom.conf
  sudo -u postgres echo "autovacuum = \$AUTOVACUUM" >> /etc/postgresql/12/main/postgresql.custom.conf
  #cat /etc/postgresql/12/main/postgresql.custom.conf
}function setPostgresPassword() {
    sudo -u postgres psql -c "ALTER USER renderer PASSWORD '\${PGPASSWORD:-renderer}'"
}
# identify the data file
    osm_data_file=\$(find /home/renderer/src/Data/  -name "*.osm.pbf" -printf "%f\n")# Initialize PostgreSQL
    createPostgresConfig
    service postgresql start
    sudo -u postgres createuser renderer
    sudo -u postgres createdb -E UTF8 -O renderer gis
    sudo -u postgres psql -d gis -c "CREATE EXTENSION postgis;"
    sudo -u postgres psql -d gis -c "CREATE EXTENSION hstore;"
    sudo -u postgres psql -d gis -c "ALTER TABLE geometry_columns    OWNER TO renderer;"
    sudo -u postgres psql -d gis -c "ALTER TABLE spatial_ref_sys OWNER TO renderer;"
    setPostgresPassword# Import data
     sudo -u renderer osm2pgsql -d gis --create --slim -G --hstore --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua ${OSM2PGSQL_EXTRA_ARGS} -S /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style /home/renderer/src/Data/$osm_data_file# Create indexes
    sudo -u postgres psql -d gis -f indexes.sql# Register that data has changed for mod_tile caching purposes
    touch /var/lib/mod_tile/planet-import-completeservice postgresql stop# Clean /tmp
    rm -rf /tmp/*# Fix postgres data privileges
    chown postgres:postgres /var/lib/postgresql -R# Configure Apache CORS
    if [ "\$ALLOW_CORS" == "1" ]; then
        echo "export APACHE_ARGUMENTS='-D ALLOW_CORS'" >> /etc/apache2/envvars
    fi# Initialize PostgreSQL and Apache
    createPostgresConfig
    service postgresql start
    service apache2 restart
    setPostgresPassword# Configure renderd threads
    sed -i -E "s/num_threads=[0-9]+/num_threads=\${THREADS:-4}/g" /usr/local/etc/renderd.conf# start cron job to trigger consecutive updates
    if [ "\$UPDATES" = "enabled" ]; then
      /etc/init.d/cron start
    fi# Run while handling docker stop's SIGTERM
    stop_handler() {
        kill -TERM "\$child"
    }
    trap stop_handler SIGTERMsudo -u renderer renderd -f -c /usr/local/etc/renderd.conf &
    child=\$!
    wait "\$child"service postgresql stop
exit 0
EOF
)

rm -f run.sh
echo "$run_script" | tee run_script.sh

cd ..
docker_compose=$(cat <<EOF
version: '3'
services:
      osm:
       build:
         context: .
         dockerfile: ./Openstreetmap/Dockerfile
       image: "openstreetmap:latest"
       ports:
         - 80:80
         - 5432:5432
       environment:
         - HOST= 0.0.0.0
EOF
)
echo "$docker_compose" | tee docker-compose.yml
docker compose build
docker compose up
