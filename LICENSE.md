# Licence

## This repository (Dockerfile, README)

MIT License

Copyright (c) 2026 <COPYRIGHT HOLDER>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Third-party components (not covered by the MIT licence above)

- **GDAL**, including the ECW driver source (`frmts/ecw`) that the build
  downloads and compiles: MIT-style licence, see
  <https://github.com/OSGeo/gdal/blob/master/LICENSE.TXT>.
- **libecwj2 3.3** (ERM ECW JPEG 2000 SDK, 2006), with patches from
  <https://github.com/rouault/libecwj2-3.3-builds>: downloaded and compiled by
  the Dockerfile, not stored here. It is under ERM's "ECW JPEG 2000 SDK PUBLIC
  USE LICENSE AGREEMENT" (included in that repository and copied into built
  images at `/opt/libecwj2-3.3/`). In short, it covers use with software
  licensed under a GPL-style licence at no charge to the public, and anyone who
  receives binaries must also be able to get the complete source and this
  licence. Other terms apply (no changes to the ECW file format, etc.). If you
  distribute an image built from this Dockerfile, make sure you comply. This is
  not legal advice; read the licence yourself. For commercial or server use you
  may need a licence from Hexagon.
- **ECW** and **ERDAS** are trademarks of Hexagon AB and/or its affiliates.
  This project is not affiliated with or endorsed by Hexagon or OSGeo.
