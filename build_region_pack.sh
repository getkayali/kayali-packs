#!/usr/bin/env bash
# KAYALI region pack builder. Produces <id>.zip (pack.json, region.pmtiles, routing.tar, places.db),
# its SHA-256, and <id>.json (the descriptor the app's "Add a region from a link" understands).
# Same pipeline as KAYALI's built-in Syria data: Planetiler (map), Valhalla (routing), OSM + Overture (search).
set -euo pipefail
ID="${ID:-saudi}"; NAME_AR="${NAME_AR:-السعودية}"; NAME_EN="${NAME_EN:-Saudi Arabia}"; VERSION="${VERSION:-$(date +%Y.%m.%d)}"
BBOX="${BBOX:-34.4,16.3,55.7,32.2}"                         # west,south,east,north
PBF_URL="${PBF_URL:-https://download.geofabrik.de/asia/gcc-states-latest.osm.pbf}"
OVERTURE_RELEASE="${OVERTURE_RELEASE:-2026-09-23.1}"       # use the newest release listed at overturemaps.org
PACK_URL="${PACK_URL:-https://example.org/$ID.zip}"        # where you will host the zip (put the real link here)
JAVA_MEM="${JAVA_MEM:-10g}"
HERE="$(cd "$(dirname "$0")" && pwd)"; W="$HERE/work-$ID"; mkdir -p "$W"; cd "$W"
echo "== 1/6 map data";      [ -f src.osm.pbf ] || curl -L -o src.osm.pbf "$PBF_URL"
osmium extract -b "$BBOX" src.osm.pbf -o region.osm.pbf --overwrite -s smart
echo "== 2/6 map tiles";     [ -f planetiler.jar ] || curl -L -o planetiler.jar https://github.com/onthegomap/planetiler/releases/latest/download/planetiler.jar
java -Xmx"$JAVA_MEM" -jar planetiler.jar --osm-path=region.osm.pbf --bounds="$BBOX" --output=region.pmtiles --force --languages=ar,en,tr --download
echo "== 3/6 routing";       mkdir -p tiles
python3 -m valhalla.valhalla_build_config --mjolnir-tile-dir "$W/tiles" --mjolnir-tile-extract "$W/routing.tar" > valhalla.json
python3 -m valhalla valhalla_build_tiles -c valhalla.json region.osm.pbf
python3 -m valhalla valhalla_build_extract -c valhalla.json -v
echo "== 4/6 places";        BBOX="$BBOX" OVERTURE_RELEASE="$OVERTURE_RELEASE" OUT="$W/overture.parquet" python3 "$HERE/tools/pull_overture.py"
OVERTURE_PARQUET="$W/overture.parquet" python3 "$HERE/tools/build_search.py" region.osm.pbf places.db
python3 "$HERE/tools/add_skeleton.py" places.db
echo "== 5/6 package"
IFS=, read -r WB SB EB NB <<< "$BBOX"
printf '{"id":"%s","name_ar":"%s","name_en":"%s","version":"%s","bbox":[%s,%s,%s,%s]}\n' "$ID" "$NAME_AR" "$NAME_EN" "$VERSION" "$WB" "$SB" "$EB" "$NB" > pack.json
rm -f "$HERE/$ID.zip"; zip -j -0 "$HERE/$ID.zip" pack.json region.pmtiles routing.tar places.db
SHA=$(sha256sum "$HERE/$ID.zip" | cut -d' ' -f1); BYTES=$(stat -c %s "$HERE/$ID.zip")
printf '{"id":"%s","url":"%s","bytes":%s,"sha256":"%s"}\n' "$ID" "$PACK_URL" "$BYTES" "$SHA" > "$HERE/$ID.json"
echo "== 6/6 done: $HERE/$ID.zip ($BYTES bytes)  sha256 $SHA"
echo "Upload $ID.zip to PACK_URL and $ID.json anywhere; in KAYALI: Regions -> Add from link -> paste the link to $ID.json"
