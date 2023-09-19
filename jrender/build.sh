#!/bin/bash

# Fetch newest
cd /src/josm-plugins \
	&& git pull \
        && git log -n 1

# Make jrender
cd /src/josm-plugins/seachart/jrender \
  && ant \
  && mv jrender.jar /build

# Make jrenderpgsql
cd /src/josm-plugins/seachart/jrenderpgsql \
  && ant \
  && mv jrenderpgsql.jar /build

