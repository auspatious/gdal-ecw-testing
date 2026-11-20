#!/bin/sh
# Smoke test: read the sample ECW/JP2 files shipped in the SDK installer with the
# built gdal-ecw image. Usage: ./test.sh [image] [installer]
set -eu
IMAGE=${1:-gdal-ecw}
BIN=${2:-binary/ERDAS_ECWJP2_SDK-5.4.0.bin}
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir "$T/x" "$T/data"
tail -n +"$(awk '/^__ARCHIVE_FOLLOWS__/ { print NR + 1; exit }' "$BIN")" "$BIN" | tar -C "$T/x" -x Common.tar.gz
tar -xzf "$T/x/Common.tar.gz" -C "$T/x" testdata
cp "$T"/x/testdata/*.ecw "$T"/x/testdata/*.jp2 "$T/data/"
docker run --rm -v "$T/data:/data" "$IMAGE" sh -ec '
  cd /data
  for f in *.ecw *.jp2; do
    gdal_translate -q "$f" "/tmp/$f.tif"
    printf "%-26s %s\n" "$f" "$(gdalinfo "$f" | grep -E "^Driver" | cut -d/ -f1)"
  done
  gdalinfo RGB_16bit_v3.ecw | grep -q "Type=UInt16"   # ECW v3 / 16-bit
  gdalinfo RGB_8bit_v3.ecw  | grep -q "Size is 1000, 1000"
  echo "ALL OK"
'
