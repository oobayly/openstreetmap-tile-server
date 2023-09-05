DOCKER_IMAGE=jrender-build
BUILD_DIR=$(shell pwd)/build/

build-docker:
	docker build -t ${DOCKER_IMAGE} ./

build: build-docker
	mkdir -p build
	rm -f build/*
	docker run --name ${DOCKER_IMAGE} ${DOCKER_IMAGE} ./build.sh
	docker cp ${DOCKER_IMAGE}:/build/jrender.jar ${BUILD_DIR}
	docker cp ${DOCKER_IMAGE}:/build/jrenderpgsql.jar ${BUILD_DIR}
	docker stop ${DOCKER_IMAGE}
	docker rm ${DOCKER_IMAGE}

console: build-docker
	docker run --rm -it ${DOCKER_IMAGE} bash
