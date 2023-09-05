#!/bin/bash

# Fetch newest
cd /src/josm-plugins \
	&& git pull

# Make jrender
cd /src/josm-plugins/seachart/jrender \
  && ant \
  && mv jrender.jar /build

# Make jrenderpgsql
cd /src/josm-plugins/seachart/jrenderpgsql \
  && ant \
  && mv jrenderpgsql.jar /build

