#!/bin/bash

mkdir -p cmake-build-corrade
cd cmake-build-corrade
cmake ../corrade/
make -j 8

cd ../
mkdir -p cmake-build
cd cmake-build
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DMAGNUM_WITH_EMSCRIPTENAPPLICATION=ON \
    -DCORRADE_RC_EXECUTABLE=../cmake-build-corrade/bin/corrade-rc
make -j 8
cd ..

