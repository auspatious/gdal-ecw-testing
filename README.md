# gdal-ecw

Adds ECW and JP2ECW support to the official [OSGeo GDAL Docker images](https://github.com/OSGeo/gdal/pkgs/container/gdal)
by building GDAL's own ECW driver (`frmts/ecw`) as a plugin
(`gdal_ECW_JP2ECW.so`). No GDAL rebuild.

It builds against the Hexagon **ERDAS ECW/JP2 SDK 5.4.0 "Desktop Read-Only
Redistributable"** installer, which you supply yourself (it is proprietary and
is not in this repo).

## Build

1. Put the installer in `binary/` (git-ignored):
   `binary/ERDAS_ECWJP2_SDK-5.4.0.bin`
2. Build:

   ```sh
   docker build -t gdal-ecw .
   ```

`GDAL_VERSION` (default `3.13.3`) selects both the base image
(`ghcr.io/osgeo/gdal:ubuntu-small-<ver>`) and the plugin source tag; they must
match exactly. Another installer filename can be passed with
`--build-arg ECW_INSTALLER=<name in binary/>` (the Dockerfile expects the 5.4
layout).

The SDK ships x86_64 libraries only, so the image is `linux/amd64` (emulated on
Apple Silicon, so the build is slow there). The final `RUN` fails the build
unless `gdalinfo --formats` lists ECW and JP2ECW.

How it works, and two workarounds for the 5.4 SDK:
- The installer is a shell script with a tar appended; the Dockerfile extracts
  the `Desktop` payload directly rather than running it interactively.
- GDAL's CMake only accepts SDK 5.5+ and looks in `lib/cpp11abi`; the build
  relaxes the version gate to 5.4 and symlinks `cpp11abi` to the SDK's `newabi`.
- Unpacking happens in a native-arch stage because `tar` fails under qemu.

## Use

```sh
docker run --rm -v "$PWD:/data" gdal-ecw gdalinfo /data/image.ecw
docker run --rm -v "$PWD:/data" gdal-ecw gdal_translate /data/image.ecw /data/out.tif
```

## Test

```sh
./test.sh            # needs the installer in binary/
```

Reads the sample ECW/JP2 files shipped inside the installer and converts each
to GeoTIFF.

## Status

Tested (GDAL 3.13.3, amd64 under emulation): image builds; `ECW` and `JP2ECW`
(SDK 5.4) register; reads ECW v2 and v3, 8-bit and 16-bit, multiband, and JP2.

Limitations:
- **No ECW writing.** The read-only SDK needs an encode key: GDAL reports
  `None of ECW_ENCODE_KEY and ECW_ENCODE_COMPANY were provided`. Writing needs a
  paid Hexagon licence.
- SDK 5.4 is from 2018 and not an officially supported combination with GDAL 3.13.
- Not tested: ECWP, other GDAL versions, large real-world files.

## Licence

See [LICENSE.md](LICENSE.md). The SDK is under Hexagon's licence. Do not publish
images built with it unless that licence allows it.
