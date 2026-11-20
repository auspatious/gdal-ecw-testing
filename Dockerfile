# syntax=docker/dockerfile:1
# GDAL ECW plugin on top of an official OSGeo GDAL image, built against the
# Hexagon ERDAS ECW JPEG 2000 SDK "Desktop Read-Only Redistributable" installer.
#
#   put ERDAS_ECWJP2_SDK-5.4.0.bin in ./binary/ (git-ignored), then:
#   docker build -t gdal-ecw .
#
# The SDK ships x86_64 libraries only, so this image is linux/amd64 (it runs
# under emulation on Apple Silicon). See README.md and LICENSE.md.
ARG GDAL_VERSION=3.13.3
ARG GDAL_IMAGE=ghcr.io/osgeo/gdal:ubuntu-small-${GDAL_VERSION}
ARG ECW_INSTALLER=ERDAS_ECWJP2_SDK-5.4.0.bin

# 1. Unpack the SDK. The installer is a shell script with a tar archive appended;
#    extract the "Desktop" payload directly instead of running it interactively.
#    Runs on the build host's native arch (tar fails under qemu emulation).
FROM --platform=$BUILDPLATFORM ${GDAL_IMAGE} AS sdk
ARG GDAL_VERSION
ARG ECW_INSTALLER
COPY binary/${ECW_INSTALLER} /tmp/ecw-installer.bin
RUN mkdir /tmp/ecw-x /opt/ecw-sdk \
 && tail -n +"$(awk '/^__ARCHIVE_FOLLOWS__/ { print NR + 1; exit }' /tmp/ecw-installer.bin)" \
      /tmp/ecw-installer.bin | tar -C /tmp/ecw-x -x Desktop.tar.gz \
 && tar -xzf /tmp/ecw-x/Desktop.tar.gz -C /opt/ecw-sdk
# GDAL's FindECW looks in lib/cpp11abi/x64/release for a libNCSEcw.so; the 5.4
# SDK calls that directory "newabi" and ships only the versioned file.
RUN cd /opt/ecw-sdk/lib && ln -s newabi cpp11abi \
 && cd newabi/x64/release && ln -s libNCSEcw.so.5.4.0 libNCSEcw.so

# GDAL sources must match the installed GDAL version exactly. GDAL's CMake only
# accepts ECW SDK 5.5+; the 5.4 SDK has the same API for what the driver uses,
# so relax the version gate.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL https://github.com/OSGeo/gdal/archive/refs/tags/v${GDAL_VERSION}.tar.gz \
    | tar xz -C /usr/src && mv /usr/src/gdal-${GDAL_VERSION} /usr/src/gdal \
 && sed -i 's/ECW_VERSION_STRING VERSION_GREATER_EQUAL 5\.5/ECW_VERSION_STRING VERSION_GREATER_EQUAL 5.4/' \
      /usr/src/gdal/cmake/modules/packages/FindECW.cmake

FROM --platform=linux/amd64 ${GDAL_IMAGE} AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake \
 && rm -rf /var/lib/apt/lists/*

COPY --from=sdk /opt/ecw-sdk /opt/ecw-sdk

COPY --from=sdk /usr/src/gdal /usr/src/gdal

# Build the plugin against the installed GDAL.
RUN cmake -S /usr/src/gdal/frmts/ecw -B /build -DCMAKE_BUILD_TYPE=Release \
      -DECW_ROOT=/opt/ecw-sdk -DCMAKE_INSTALL_PREFIX=/usr -DSTRICT_VERSION_CHECK=ON \
 && cmake --build /build -j"$(nproc)" \
 && DESTDIR=/out cmake --install /build

FROM --platform=linux/amd64 ${GDAL_IMAGE}
COPY --from=build /out/ /
COPY --from=build /opt/ecw-sdk/lib/newabi/x64/release/libNCSEcw.so.5.4.0 /usr/local/lib/
COPY --from=build /opt/ecw-sdk/include/ECWJP2BuildNumber.h /usr/share/doc/gdal-ecw/
RUN ldconfig \
 && gdalinfo --formats | grep -E '^ *ECW ' \
 && gdalinfo --formats | grep -E '^ *JP2ECW '
