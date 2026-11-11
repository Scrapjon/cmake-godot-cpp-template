cmake_minimum_required(VERSION 3.20)

# ---------------------------------------------------------------------------
# Project options
# ---------------------------------------------------------------------------
# The one place the extension is named. It drives the library file name, the generated
# .gdextension file (from build_schemas/extension.gdextension.in) and the entry symbol.
set(LIBNAME "example" CACHE STRING "Extension name")
# Leave empty to derive "<name>_library_init" from LIBNAME.
set(EXT_ENTRY_SYMBOL "" CACHE STRING "GDExtension entry symbol (empty = derived from LIBNAME)")
set(GODOT_PROJECT_DIR "project" CACHE STRING "The directory of a Godot project folder")

# Language standard for BOTH godot-cpp and this extension.
# godot-cpp itself needs at least C++17.
set(EXT_CXX_STANDARD "23" CACHE STRING "C++ standard to build with (17, 20, 23, 26)")
set_property(CACHE EXT_CXX_STANDARD PROPERTY STRINGS 17 20 23 26)

if(EXT_CXX_STANDARD LESS 17)
    message(FATAL_ERROR "godot-cpp requires C++17 or newer (EXT_CXX_STANDARD=${EXT_CXX_STANDARD})")
endif()
if(EXT_CXX_STANDARD GREATER_EQUAL 26 AND CMAKE_VERSION VERSION_LESS 3.25)
    message(FATAL_ERROR "C++26 needs CMake 3.25+ (found ${CMAKE_VERSION})")
endif()

# Set before godot-cpp so global defaults match. godot-cpp pins its own target to 17,
# so we also override that target explicitly below.
set(CMAKE_CXX_STANDARD ${EXT_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Godot API version the bindings are generated from. Newer godot-cpp requires this to be
# chosen by the consumer. Lower = works with more Godot versions, higher = newer APIs.
# Keep compatibility_minimum in the .gdextension file in step with it.
# (Passing -DGODOTCPP_API_VERSION=x.y directly also works and takes precedence.)
set(GODOT_API_VERSION "4.3" CACHE STRING "Godot API version to generate bindings for (4.3 ... 4.8)")
set(GODOTCPP_DEFAULT_API_VERSION "${GODOT_API_VERSION}")

# Silence unused variable warning when specified from toolchain
if(CMAKE_C_COMPILER)
endif()

# ---------------------------------------------------------------------------
# godot-cpp (add it as a submodule at ./godot-cpp)
# ---------------------------------------------------------------------------
if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/godot-cpp/CMakeLists.txt")
    message(FATAL_ERROR
        "godot-cpp not found at ${CMAKE_CURRENT_LIST_DIR}/godot-cpp\n"
        "Add it with:\n"
        "  git submodule add https://github.com/godotengine/godot-cpp.git godot-cpp\n"
        "  git submodule update --init --recursive")
endif()
add_subdirectory(godot-cpp SYSTEM)

set_target_properties(godot-cpp PROPERTIES
    CXX_STANDARD ${EXT_CXX_STANDARD}
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF)

# When compiling for emscripten, this toolchainhack needs to be included.
# set(CMAKE_PROJECT_<project-name>_INCLUDE ${godot-cpp_SOURCE_DIR}/cmake/emsdkHack.cmake)

# Create the gen directory at configure time so IDEs can see generated headers immediately
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/godot-cpp/gen/include")

# godot-cpp's module path and exported functions (used for documentation generation)
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${godot-cpp_SOURCE_DIR}/cmake")
include(GodotCPPModule)

# Useful properties attached to the godot-cpp target
get_target_property(GODOTCPP_SUFFIX godot::cpp GODOTCPP_SUFFIX)
get_target_property(GODOTCPP_PLATFORM godot::cpp GODOTCPP_PLATFORM)

# ---------------------------------------------------------------------------
# The extension
# ---------------------------------------------------------------------------
if(NOT EXT_ENTRY_SYMBOL)
    string(MAKE_C_IDENTIFIER "${LIBNAME}" _libname_id)
    set(EXT_ENTRY_SYMBOL "${_libname_id}_library_init")
endif()

# compatibility_minimum for the .gdextension follows the API version in use
if(GODOTCPP_API_VERSION)
    set(EXT_COMPAT_MIN "${GODOTCPP_API_VERSION}")
else()
    set(EXT_COMPAT_MIN "${GODOT_API_VERSION}")
endif()

project(godot-cpp-template
    VERSION 1.0
    DESCRIPTION "Quickstart template for GDExtension development with Godot 4.0+."
    LANGUAGES CXX
)

add_library(${LIBNAME} SHARED)

# Pick up every .cpp/.h under src/ (re-globbed automatically when files are added)
file(GLOB_RECURSE EXT_SOURCES CONFIGURE_DEPENDS
    "${PROJECT_SOURCE_DIR}/src/*.cpp"
    "${PROJECT_SOURCE_DIR}/src/*.h")
target_sources(${LIBNAME} PRIVATE ${EXT_SOURCES})

# Let any file include headers relative to src/, e.g. #include "gameplay/player.h"
target_include_directories(${LIBNAME} PRIVATE "${PROJECT_SOURCE_DIR}/src")

# Documentation XML (editor/debug builds only)
file(GLOB_RECURSE DOC_XML LIST_DIRECTORIES NO CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/doc_classes/*.xml")
if(DOC_XML)
    if(GODOTCPP_TARGET MATCHES "editor|template_debug")
        target_doc_sources(${LIBNAME} "${DOC_XML}")
    endif()
endif()

target_link_libraries(${LIBNAME} PRIVATE godot-cpp)
target_compile_definitions(${LIBNAME} PRIVATE GDEXT_ENTRY_SYMBOL=${EXT_ENTRY_SYMBOL})

# Generate <name>.gdextension next to the built libraries from the schema.
# It is written at configure time AND by a build step, so deleting it and building again
# brings it back on every generator. It is rewritten only when its content changes.
set(EXT_GDEXTENSION_SCHEMA "${PROJECT_SOURCE_DIR}/build_schemas/extension.gdextension.in")
set(EXT_GDEXTENSION_OUT "${PROJECT_SOURCE_DIR}/${GODOT_PROJECT_DIR}/bin/${LIBNAME}.gdextension")

configure_file("${EXT_GDEXTENSION_SCHEMA}" "${EXT_GDEXTENSION_OUT}" @ONLY)

add_custom_command(
    OUTPUT "${EXT_GDEXTENSION_OUT}"
    COMMAND ${CMAKE_COMMAND}
        "-DSCHEMA=${EXT_GDEXTENSION_SCHEMA}"
        "-DOUTPUT=${EXT_GDEXTENSION_OUT}"
        "-DLIBNAME=${LIBNAME}"
        "-DEXT_ENTRY_SYMBOL=${EXT_ENTRY_SYMBOL}"
        "-DEXT_COMPAT_MIN=${EXT_COMPAT_MIN}"
        -P "${PROJECT_SOURCE_DIR}/cmake/GenerateGDExtension.cmake"
    DEPENDS "${EXT_GDEXTENSION_SCHEMA}" "${PROJECT_SOURCE_DIR}/cmake/GenerateGDExtension.cmake"
    COMMENT "Generating ${LIBNAME}.gdextension"
    VERBATIM
)
add_custom_target(${LIBNAME}_gdextension ALL DEPENDS "${EXT_GDEXTENSION_OUT}")
add_dependencies(${LIBNAME} ${LIBNAME}_gdextension)

set_target_properties(${LIBNAME} PROPERTIES
    CXX_STANDARD ${EXT_CXX_STANDARD}
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF

    # Build straight into the Godot project. The generator expression stops
    # MSVC/Xcode from adding a Debug/Release subdirectory.
    LIBRARY_OUTPUT_DIRECTORY "$<1:${PROJECT_SOURCE_DIR}/${GODOT_PROJECT_DIR}/bin/${GODOTCPP_PLATFORM}>"
    RUNTIME_OUTPUT_DIRECTORY "$<1:${PROJECT_SOURCE_DIR}/${GODOT_PROJECT_DIR}/bin/${GODOTCPP_PLATFORM}>"

    # Default prefix is kept (lib on Linux/macOS, none on Windows) to match the .gdextension paths
    OUTPUT_NAME "${LIBNAME}${GODOTCPP_SUFFIX}"
)

message(STATUS "C++ standard : ${EXT_CXX_STANDARD}")
message(STATUS "Extension    : ${LIBNAME} (entry: ${EXT_ENTRY_SYMBOL}, min Godot: ${EXT_COMPAT_MIN})")
