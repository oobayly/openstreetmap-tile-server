FROM ubuntu:22.04 AS compiler-common
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 ca-certificates gnupg lsb-release locales \
 wget curl \
 git-core unzip unrar \
&& locale-gen $LANG && update-locale LANG=$LANG \
&& sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
&& wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
&& apt-get update && apt-get -y upgrade

###########################################################################################################

FROM compiler-common AS compiler-stylesheet
RUN cd ~ \
&& git clone --single-branch --branch v5.4.0 https://github.com/gravitystorm/openstreetmap-carto.git --depth 1 \
&& cd openstreetmap-carto \
&& sed -i 's/, "unifont Medium", "Unifont Upper Medium"//g' style/fonts.mss \
&& sed -i 's/"Noto Sans Tibetan Regular",//g' style/fonts.mss \
&& sed -i 's/"Noto Sans Tibetan Bold",//g' style/fonts.mss \
&& sed -i 's/Noto Sans Syriac Eastern Regular/Noto Sans Syriac Regular/g' style/fonts.mss \
&& rm -rf .git

###########################################################################################################

FROM compiler-common AS compiler-helper-script
RUN mkdir -p /home/renderer/src \
&& cd /home/renderer/src \
&& git clone https://github.com/zverik/regional \
&& cd regional \
&& rm -rf .git \
&& chmod u+x /home/renderer/src/regional/trim_osc.py

###########################################################################################################

FROM compiler-common AS final

# Based on
# https://switch2osm.org/serving-tiles/manually-building-a-tile-server-18-04-lts/
ENV DEBIAN_FRONTEND=noninteractive
ENV AUTOVACUUM=on
ENV UPDATES=disabled
ENV REPLICATION_URL=https://planet.openstreetmap.org/replication/hour/
ENV MAX_INTERVAL_SECONDS=3600
ENV PG_VERSION 15

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Get packages
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 apache2 \
 cron \
 dateutils \
 fonts-hanazono \
 fonts-noto-cjk \
 fonts-noto-hinted \
 fonts-noto-unhinted \
 fonts-unifont \
 gnupg2 \
 gdal-bin \
 liblua5.3-dev \
 lua5.3 \
 mapnik-utils \
 npm \
 osm2pgsql \
 osmium-tool \
 osmosis \
 postgresql-$PG_VERSION \
 postgresql-$PG_VERSION-postgis-3 \
 postgresql-$PG_VERSION-postgis-3-scripts \
 postgis \
 python-is-python3 \
 python3-mapnik \
 python3-lxml \
 python3-psycopg2 \
 python3-shapely \
 python3-pip \
 renderd \
 sudo \
 tirex \
 vim \
&& apt-get clean autoclean \
&& apt-get autoremove --yes \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN adduser --disabled-password --gecos "" renderer


# Get Noto Emoji Regular font, despite it being deprecated by Google
RUN wget https://github.com/googlefonts/noto-emoji/blob/9a5261d871451f9b5183c93483cbd68ed916b1e9/fonts/NotoEmoji-Regular.ttf?raw=true --content-disposition -P /usr/share/fonts/

# For some reason this one is missing in the default packages
RUN wget https://github.com/stamen/terrain-classic/blob/master/fonts/unifont-Medium.ttf?raw=true --content-disposition -P /usr/share/fonts/

# Install python libraries
RUN pip3 install \
 requests \
 osmium \
 pyyaml

# Install carto for stylesheet
RUN npm install -g carto@1.2.0

# Configure Apache
RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
&& echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
&& a2enconf mod_tile && a2enconf mod_headers
COPY apache.conf /etc/apache2/sites-available/000-default.conf
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
&& ln -sf /dev/stderr /var/log/apache2/error.log

# leaflet-demo
RUN rm -Rf /var/www/html/*
COPY leaflet-demo.html /var/www/html/index.html

# Icon
RUN wget -O /var/www/html/favicon.ico https://www.openstreetmap.org/favicon.ico

# Copy update scripts
COPY openstreetmap-tiles-update-expire.sh /usr/bin/
RUN chmod +x /usr/bin/openstreetmap-tiles-update-expire.sh \
&& mkdir /var/log/tiles \
&& chmod a+rw /var/log/tiles \
&& ln -s /home/renderer/src/mod_tile/osmosis-db_replag /usr/bin/osmosis-db_replag \
&& echo "* * * * *   renderer    openstreetmap-tiles-update-expire.sh\n" >> /etc/crontab

# Configure PosgtreSQL
COPY postgresql.custom.conf.tmpl /etc/postgresql/$PG_VERSION/main/
RUN chown -R postgres:postgres /var/lib/postgresql \
&& chown postgres:postgres /etc/postgresql/$PG_VERSION/main/postgresql.custom.conf.tmpl \
&& echo "host all all 0.0.0.0/0 scram-sha-256" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf \
&& echo "host all all ::/0 scram-sha-256" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# Create volume directories
RUN mkdir -p /run/renderd/ \
  &&  mkdir  -p  /data/database/  \
  &&  mkdir  -p  /data/style/  \
  &&  mkdir  -p  /home/renderer/src/  \
  &&  chown  -R  renderer:  /data/  \
  &&  chown  -R  renderer:  /home/renderer/src/  \
  &&  chown  -R  renderer:  /run/renderd  \
  &&  mv  /var/lib/postgresql/$PG_VERSION/main/  /data/database/postgres/  \
  &&  mv  /var/cache/renderd/tiles/            /data/tiles/     \
  &&  chown  -R  renderer: /data/tiles \
  &&  ln  -s  /data/database/postgres  /var/lib/postgresql/$PG_VERSION/main             \
  &&  ln  -s  /data/style              /home/renderer/src/openstreetmap-carto  \
  &&  ln  -s  /data/tiles              /var/cache/renderd/tiles                \
  &&  chmod 775 /data/tiles \
;

# Install helper script
COPY --from=compiler-helper-script /home/renderer/src/regional /home/renderer/src/regional

COPY --from=compiler-stylesheet /root/openstreetmap-carto /home/renderer/src/openstreetmap-carto-backup

# Copy tirex configuration
RUN mkdir -p /etc/tirex/renderer/openseamap
COPY openseamap.conf /etc/tirex/renderer/openseamap.conf
COPY openseamap-renderer.conf /etc/tirex/renderer/openseamap/openseamap.conf
COPY tirex.conf /etc/tirex/tirex.conf

# Link tirex to /data/tiles too
RUN  rm -Rf /var/cache/tirex/tiles \
  && ln -s /data/tiles /var/cache/tirex/tiles

# tirex will be run as the renderer user
# but we're not using systemd
RUN  mkdir -p /var/run/tirex \
  && chown renderer:renderer /var/cache/tirex \
  && chown renderer:renderer /var/cache/tirex/stats \
  && chown renderer:renderer /var/run/tirex \
  && chown renderer:renderer /var/log/tirex \
  && sed -i 's/_tirex/renderer/g' /usr/lib/systemd/system/tirex-master.service \
  && sed -i 's/_tirex/renderer/g' /usr/lib/systemd/system/tirex-backend-manager.service

# Remove unrequired tirex sample renderer and maps
RUN  rm -fr /etc/tirex/renderer/mapnik.conf \
  && rm -fr /etc/tirex/renderer/wms \
	&& rm -fr /etc/tirex/renderer/mapserver \
	&& rm -fr /etc/tirex/renderer/test \
	&& rm -fr /etc/tirex/renderer/wms.conf \
	&& rm -fr /etc/tirex/renderer/mapserver.conf \
	&& rm -fr /etc/tirex/renderer/test.conf

RUN  mkdir -p /srv/jrenderpgsql/
COPY tirex-backend-openseamap /usr/libexec/tirex-backend-openseamap
COPY jrenderpgsql.jar /srv/jrenderpgsql/jrenderpgsql.jar
RUN chown renderer: /srv/jrenderpgsql/jrenderpgsql.jar

# Start running
COPY run.sh /
ENTRYPOINT ["/run.sh"]
CMD []
EXPOSE 80 5432
