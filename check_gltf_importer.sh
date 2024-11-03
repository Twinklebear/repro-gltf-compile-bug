#!/bin/bash

wat_file=gltfimporter.wat 

wasm2wat \
    magnum-plugins/src/MagnumPlugins/GltfImporter/CMakeFiles/GltfImporter.dir/GltfImporter.cpp.o \
    -o $wat_file \
    --enable-all \
    --generate-names

grep -n "i64.load offset=4294967280" $wat_file 

