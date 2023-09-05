docker build -t jrender-build ./

mkdir -p build
docker run --rm -v "$(pwd)/build:/build" jrender-build ./build.sh
