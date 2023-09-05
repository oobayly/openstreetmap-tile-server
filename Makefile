.PHONY: build push test

DOCKER_IMAGE=oobayly/openseamap-tile-server



build:
	docker build -t ${DOCKER_IMAGE} .

push: build
	docker push ${DOCKER_IMAGE}:latest

test:build
	docker volume create osm-data
	docker run --rm -v osm-data:/data/database/ ${DOCKER_IMAGE} import
	docker run --rm -v osm-data:/data/database/ -p 8080:80 -d ${DOCKER_IMAGE} run

import:# build
	docker run \
	--rm \
	-v $(shell pwd)/osm-data/seamarks_planet.osm:/data/region.osm \
	-v osm-data:/data/database/ \
	-v osm-tiles:/data/tiles/ \
	${DOCKER_IMAGE} \
	import

serve:# build
	docker run \
	--rm \
	-p 8080:80 \
	-v osm-data:/data/database/ \
	-v osm-tiles:/data/tiles/ \
	-e ALLOW_CORS=enabled \
	${DOCKER_IMAGE} \
	run

stop:
	docker rm -f `docker ps | grep '${DOCKER_IMAGE}' | awk '{ print $$1 }'` || true
