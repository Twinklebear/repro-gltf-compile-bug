add_executable(repro_lib repro_lib.cpp)
target_link_libraries(repro_lib PUBLIC Magnum::EmscriptenApplication)

target_link_options(
  repro_lib
  PRIVATE
  "SHELL:-sENVIRONMENT='web'"
  -sWASM=1
  -sFETCH=1
  -sALLOW_MEMORY_GROWTH=1
  -sALLOW_TABLE_GROWTH=1
  -sUSE_WEBGL2=1
  -sMIN_WEBGL_VERSION=2
  -sMAX_WEBGL_VERSION=2
  -sMODULARIZE=1
  -sEXPORT_ES6
  -sEXPORT_NAME=ReproLib
  -sMAXIMUM_MEMORY=4GB
  # Note: In some browsers the textdecoder API doesn't work with
  # SharedArrayBuffers, so we disable it.
  -sTEXTDECODER=0
  -sINVOKE_RUN=0
  # We are building a library for JS, so we don't need or want runtime exit
  # support
  -sEXIT_RUNTIME=0
  "SHELL:-sEXPORTED_FUNCTIONS='[\"_main\"]'"
  # Debug build flags
  $<$<CONFIG:DEBUG>:-sASSERTIONS>
  $<$<CONFIG:DEBUG>:-O0>
  $<$<CONFIG:DEBUG>:-g>
  # RelWithDebInfo build flags
  $<$<CONFIG:RELWITHDEBINFO>:-sASSERTIONS>
  $<$<CONFIG:RELWITHDEBINFO>:-O2>
  $<$<CONFIG:RELWITHDEBINFO>:-g>)

option(
  ENABLE_SPLIT_DWARF
  "Enable split DWARF in RelWithDebInfo builds (required to publish npm package)"
  ON)
set(ENABLE_SPLIT_DWARF_EXPR
    "$<AND:$<BOOL:${ENABLE_SPLIT_DWARF}>,$<CONFIG:RELWITHDEBINFO>>")
target_link_options(
  repro_lib
  PRIVATE
  $<${ENABLE_SPLIT_DWARF_EXPR}:-gseparate-dwarf=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/repro_lib.dwarf>
)

target_link_libraries(
  repro_lib
  PUBLIC Corrade::Main
         Magnum::GL
         Magnum::Magnum
         Magnum::Shaders
         Magnum::Primitives
         Magnum::DebugTools
         Magnum::Text
         Magnum::MagnumFont
         MagnumPlugins::GltfImporter)
