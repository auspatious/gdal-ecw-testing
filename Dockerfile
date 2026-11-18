# syntax=docker/dockerfile:1
# GDAL ECW plugin on top of an official OSGeo GDAL image, using the open-source
# libecwj2 3.3 SDK (patched by Even Rouault) instead of the Hexagon SDK.
#
#   docker build -t gdal-ecw .
#
# See README.md and LICENSE.md: libecwj2 is under ERM's "Public Use" licence.
ARG GDAL_VERSION=3.13.3
ARG GDAL_IMAGE=ghcr.io/osgeo/gdal:ubuntu-small-${GDAL_VERSION}
ARG LIBECWJ2_REF=baa84cf8ee3e91f1fd0eb127a6a0d1fe1d84884d

FROM ${GDAL_IMAGE} AS build
ARG GDAL_VERSION
ARG LIBECWJ2_REF
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake curl ca-certificates git unzip patch autotools-dev \
 && rm -rf /var/lib/apt/lists/*

# 1. libecwj2 3.3 (+ Rouault's patches) -> /opt/libecwj2-3.3
RUN git clone https://github.com/rouault/libecwj2-3.3-builds /usr/src/libecwj2-builds \
 && git -C /usr/src/libecwj2-builds checkout ${LIBECWJ2_REF} \
 && cd /tmp && unzip -q /usr/src/libecwj2-builds/libecwj2-3.3-2006-09-06.zip \
 && patch -p0 < /usr/src/libecwj2-builds/libecwj2-3.3.patch \
 && cd libecwj2-3.3 \
 && for f in config.guess config.sub; do find . -name $f -exec cp /usr/share/misc/$f {} \; ; done \
 && CFLAGS="-O2 -w" CXXFLAGS="-O2 -w -std=gnu++98 -fpermissive" \
    ./configure --prefix=/opt/libecwj2-3.3 \
 && make -j"$(nproc)" && mkdir -p /opt/libecwj2-3.3/include && make install

# 2. GDAL ECW plugin; sources must match the installed GDAL version exactly.
RUN curl -fsSL https://github.com/OSGeo/gdal/archive/refs/tags/v${GDAL_VERSION}.tar.gz \
    | tar xz -C /usr/src && mv /usr/src/gdal-${GDAL_VERSION} /usr/src/gdal
RUN cmake -S /usr/src/gdal/frmts/ecw -B /build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=/opt/libecwj2-3.3 -DCMAKE_INSTALL_PREFIX=/usr -DSTRICT_VERSION_CHECK=ON \
 && cmake --build /build -j"$(nproc)" \
 && DESTDIR=/out cmake --install /build

FROM ${GDAL_IMAGE}
COPY --from=build /out/ /
COPY --from=build /opt/libecwj2-3.3/lib /opt/libecwj2-3.3/lib
COPY --from=build /usr/src/libecwj2-builds/License-libecwj2-3.3-2006-09-06.txt /opt/libecwj2-3.3/
RUN echo /opt/libecwj2-3.3/lib > /etc/ld.so.conf.d/libecwj2.conf && ldconfig \
 && gdalinfo --formats | grep -E '^ *ECW ' \
 && gdalinfo --formats | grep -E '^ *JP2ECW '
