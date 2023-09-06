#!/bin/bash

# [timeout:3600];(rel['seamark:type'];>;way['seamark:type'];>;node['seamark:type'];);out meta;

OVERPASS="[timeout:3600];("
NEWER=
TMP=$(tempfile -d /var/tmp/)

if [ -n "$1" ]; then
	NEWER="(newer:'$(date -d $1 +%FT%T.%2NZ)')"
fi

for t in rel way node; do
	OVERPASS="${OVERPASS}\n$t['seamark:type']"
	if [ -n "$NEWER" ]; then
		OVERPASS="${OVERPASS}${NEWER}"
	fi
	OVERPASS="${OVERPASS};>;";
done

OVERPASS="${OVERPASS}\n);\nout meta;"

echo "Querying OverPass:"
echo -e $OVERPASS

echo -e "${OVERPASS}" | curl -X POST --data @- "http://overpass-api.de/api/interpreter" > "$TMP"

mv "$TMP" osm-data/seamarks_planet.osm

