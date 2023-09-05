docker run \
    -v /mnt/d/osm/seamarks-planet.osm:/data/region.osm \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    openseamap-tile-server \
    import

docker run \
    -p 8080:80 \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    -e ALLOW_CORS=enabled \
    -it openseamap-tile-server \
    bash
    
docker run \
    -p 8080:80 \
    -v osm-data:/data/database/ \
    -v osm-tiles:/data/tiles/ \
    -e ALLOW_CORS=enabled \
    openseamap-tile-server \
    run      

sudo -u _tirex tirex-backend-manager -f &
sudo -u _tirex tirex-master -d -f &
