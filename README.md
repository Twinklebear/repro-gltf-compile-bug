# Emscripten 3.1.65 Compile Bug Repro Case

This repro case is for a compile bug that seems to have been introduced
in Emscripten 3.1.66 when compiling [this lambda](https://github.com/mosra/magnum-plugins/blob/master/src/MagnumPlugins/GltfImporter/GltfImporter.cpp#L3349)
in Magnum's GLTF importer.

On Emscripten 3.1.65 the following block is emitted before the call
to `Corrade::Utility::operator==(Corrade::Utility::StringView, Corrade::Utility::StringView)`:
```wat
local.get $p2
i32.load offset=12
local.get $p2
i32.const 4
i32.sub
i32.load
i32.eq
if $I26
  local.get $l4
  local.get $p2
  i64.load align=4
  local.tee $l8
  i64.store offset=504
  local.get $l4
  local.get $p2
  i32.const 16
  i32.sub
  i64.load align=4
  local.tee $l18
  i64.store offset=880
  local.get $l4
  local.get $l8
  i64.store offset=448
  local.get $l4
  local.get $l18
  i64.store offset=440
  i32.const 0
  local.set $l6
  local.get $l4
  i32.const 448
  i32.add
  local.get $l4
  i32.const 440
  i32.add
  call $Corrade::Containers::operator==_Corrade::Containers::BasicStringView<char_const>__Corrade::Containers::BasicStringView<char_const>_
  br_if $B24
end
```

However, starting with 3.1.66, the second `i64.load` here starts being emitted
with an offset of uint32 max, causing a memory out of bounds error to occur.
```wat
local.get $p2
i32.load offset=12
local.get $p2
i32.const 4
i32.sub
i32.load
i32.eq
if $I26
  local.get $l4
  local.get $p2
  i64.load align=4
  local.tee $l8
  i64.store offset=504
  local.get $l4
  local.get $p2
  i64.load offset=4294967280 align=4
  local.tee $l18
  i64.store offset=880
  local.get $l4
  local.get $l8
  i64.store offset=448
  local.get $l4
  local.get $l18
  i64.store offset=440
  i32.const 0
  local.set $l6
  local.get $l4
  i32.const 448
  i32.add
  local.get $l4
  i32.const 440
  i32.add
  call $Corrade::Containers::operator==_Corrade::Containers::BasicStringView<char_const>__Corrade::Containers::BasicStringView<char_const>_
  br_if $B24
end
```

# Building the Repro Case

Cross-compiling w/ Magnum takes a small bit of setup so I've provided a
build script, `build.sh` that will build the host utility `corrade-rc` and
then build the WASM code. After running `build.sh` you can inspect the output
under `cmake-build/bin/repro_lib.wasm` and translate it to wat with `wasm2wat`
to see the good/bad output.

```bash
git clone --recurse-submodules git@github.com:Twinklebear/repro-gltf-compile-bug.git
cd repro-gltf-compile-bug
./build.sh
```

Then use `wasm2wat` to inspect the output on 3.1.64 and 3.1.65+:
```bash
wasm2wat ./cmake-build/bin/repro_lib.wasm --generate-names --enable-all -o out.wat
```

To find the failing code grep for
```
call $void_std::__2::__stable_sort<std::__2::_ClassicAlgPolicy__Magnum::Trade::GltfImporter::doMesh_unsigned_int__unsigned_int_::$_0&__Corrade::Containers::Triple<Corrade::Containers::BasicStringView<char_const>__unsigned_int__int>*>_Corrade::Containers::Triple<Corrade::Containers::BasicStringView<char_const>__unsigned_int__int>*__Corrade::Containers::Triple<Corrade::Containers::BasicStringView<char_const>__unsigned_int__int>*__Magnum::Trade::GltfImporter::doMesh_unsigned_int__unsigned_int_::$_0&__std::__2::iterator_traits<Corrade::Containers::Triple<Corrade::Containers::BasicStringView<char_const>__unsigned_int__int>*>::difference_type__std::__2::iterator_traits<Corrade::Containers::Triple<Corrade::Containers::BasicStringView<char_const>__unsigned_int__int>*>::value_type*__long_
```
and find the occurrance that is followed almost immediately by `call $operator_delete_void*_`
and if you scroll down just a bit you should find a call:
```
call $Corrade::Containers::operator==_Corrade::Containers::BasicStringView<char_const>__Corrade::Containers::BasicStringView<char_const>_
```

Above this call to `operator==` are two `i64.load`, the second of which gets the bad offset
on 3.1.65+


