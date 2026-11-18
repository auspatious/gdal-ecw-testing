# gdal-ecw

Adds ECW and JP2ECW support to the official [OSGeo GDAL Docker images](https://github.com/OSGeo/gdal/pkgs/container/gdal)
by building GDAL's own ECW driver (`frmts/ecw`) as a plugin
(`gdal_ECW_JP2ECW.so`). No GDAL rebuild, and no Hexagon account needed: it uses
the open-source **libecwj2 3.3** SDK, patched and mirrored by Even Rouault
([rouault/libecwj2-3.3-builds](https://github.com/rouault/libecwj2-3.3-builds)),
which the Dockerfile builds from source (pinned commit).

## Build

```sh
docker build -t gdal-ecw .
```

Works natively on arm64 and amd64. `GDAL_VERSION` (default `3.13.3`) selects
both the base image (`ghcr.io/osgeo/gdal:ubuntu-small-<ver>`) and the plugin
source tag; they must match exactly. Override `GDAL_IMAGE` to use another
flavour (e.g. `ubuntu-full`).

The final `RUN` fails the build unless `gdalinfo --formats` lists ECW and JP2ECW.

## Use

```sh
docker run --rm -v "$PWD:/data" gdal-ecw gdalinfo /data/image.ecw
docker run --rm -v "$PWD:/data" gdal-ecw gdal_translate /data/image.ecw /data/out.tif
```

To add it to your own image instead, copy `/usr/lib/*/gdalplugins/gdal_ECW_JP2ECW.so`
and `/opt/libecwj2-3.3` from the built image, then add
`/opt/libecwj2-3.3/lib` to the linker path (`ldconfig`).

## Status

Tested (GDAL 3.13.3, arm64): image builds; `ECW` and `JP2ECW` drivers register;
a GeoTIFF was written to ECW and JP2 and the ECW read back with the expected
pixel statistics (lossy compression).

Not tested: amd64, other GDAL versions, ECWP, large or real-world ECW files.

## Limitations of libecwj2 3.3 (vs the Hexagon 5.x SDK)

- Dated (2006) code; unmaintained, patched only for building.
- ECW version 3 files and 16-bit ECW are very likely unsupported (GDAL documents
  these as needing the 5.x SDK). Files from recent software may fail to open.
- If you hit that, fall back to the Hexagon SDK, which needs an account.

## Licence

See [LICENSE.md](LICENSE.md). libecwj2 is under ERM's "Public Use" licence, which
has conditions on redistributing built images. Read it before publishing one.
