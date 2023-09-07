# OpenSeaMap Tile Server configuration

This is a modified fork of [Overv/openstreetmap-tile-server](https://github.com/Overv/openstreetmap-tile-server) that will serve just OpenSeaMap SeaMark tiles, similar to `https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png`.

## Changes made
- Only imports nodes, ways and relations that contain the `seamark:type` tag. These are fetched using the overpass API
- Uses [tirex](https://github.com/openstreetmap/tirex) instead of renderd so the OpenSeaMap backend can be used
- Users a modified version of [jrenderpgsql.jar](https://github.com/oobayly/josm-plugins.git/) that will actually build, and that will generate valid XML [#23157 [patch] Fix jrenderpgsql build errors](https://josm.openstreetmap.de/ticket/23157)

## TODO
- Reduce reliance on mapnik in order to reduce Docker image size and complexity
- Implement automatic updates

## Build instructions

The build process is fairly simple

Fork the repo and checkout the openseamap branch
```bash
git clone https://github.com/oobayly/openstreetmap-tile-server.git
cd openstreetmap-tile-server
git checkout openseamap
```

Build the modified jrenderpgsql.jar file
```bash
make jrender
```

Fetch the seamark data from [OverPass](https://overpass-turbo.eu/). You may want to download a smaller extract at first for testing
```bash
make fetch-planet
```

Build the docker image
```bash
make build
```

Import the seamark data. If you've downloaded a custom extract instead of the using the `fetch` recipe, the file should be available at `./osm-data/seamarks_planet.osm`
```bash
make import
```

Run the image to make sure there are no errors
```bash
docker-compose up map
```

Or as a background process
```bash
docker-compose up -d map
```

The map will be available at [localhost:8080](http://localhost:8080/)

## Optional commands

View the tirex master status
```bash
docker exec -it openseamap-tile-server tirex-status
```

Prerender tiles. you can pass any arguments as specified by [tirex-batch](https://wiki.openstreetmap.org/wiki/Tirex/Commands/tirex-batch), except the `map` INIT value, which is added automatically
```bash
# Ireland, Zoom Level 7 to 8, Get counts only
docker exec -it openseamap-tile-server /pre-render.sh --count-only z=7-8 bbox=-9.97708574059,51.6693012559,-6.03298539878,55.1316222195
```

## Running on a public facing server

If the tile server needs to run public facing website, the best option is to use a reverse proxy rather than exposing the tile server docker port directly. Using [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) and [acme-companion](https://github.com/nginx-proxy/acme-companion), it's incredibly simple to configure. All that needs to be done is to point a domain to the server in question and use the following `docker-compose.yml`.

Just replace the `<YOUR EMAIL>` and `<YOUR HOSTNAME>` with a valid email (for [LetsEncrypt](https://letsencrypt.org/)) and the hostname on which the tile server will be accessible.

```YAML
version: '3'

services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy:alpine
    container_name: nginx-proxy
    restart: always
    depends_on:
      - nginx-proxy-acme
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - proxy-certs:/etc/nginx/certs
      - proxy-vhost:/etc/nginx/vhost.d
      - proxy-html:/usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro

  nginx-proxy-acme:
    image: nginxproxy/acme-companion:latest
    container_name: nginx-proxy-acme
    restart: always
    environment:
      - DEFAULT_EMAIL=<YOUR EMAIL>
      - NGINX_PROXY_CONTAINER=nginx-proxy
    volumes:
      - proxy-certs:/etc/nginx/certs
      - proxy-vhost:/etc/nginx/vhost.d
      - proxy-html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - acme:/etc/acme.sh

  tiles-openseamap:
    image: oobayly/openseamap-tile-server:latest
    container_name: openseamap-tile-server
    restart: always
    expose:
      - 80
    environment:
      - VIRTUAL_HOST=<YOUR HOSTNAME>
      - LETSENCRYPT_HOST=<YOUR HOSTNAME>
      - ALLOW_CORS=enabled
    volumes:
      - osm-data:/data/database/
      - osm-tiles:/data/tiles/
    command: run

volumes:
  osm-data:
    external: true
  osm-tiles:
    external: true
  proxy-certs:
    external: true   
  proxy-vhost:
    external: true
  proxy-html:
    external: true
  acme:
```
