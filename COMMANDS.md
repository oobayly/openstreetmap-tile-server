docker build -t openseamap-tile-server ./

docker run \
    --rm \
    -v /mnt/d/osm/seamarks-planet.osm:/data/region.osm \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    openseamap-tile-server \
    import

docker run \
    --rm \
    --entrypoint bash \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    -it openseamap-tile-server
    
docker run \
    --rm \
    -p 8080:80 \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    -e ALLOW_CORS=enabled \
    openseamap-tile-server \
    run

docker run \
    --rm \
    -p 8080:80 \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    -e ALLOW_CORS=enabled \
    -d openseamap-tile-server \
    run

sudo -u _tirex tirex-backend-manager -f &
sudo -u _tirex tirex-master -d -f &
