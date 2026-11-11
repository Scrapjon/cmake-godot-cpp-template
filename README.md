# godot-cpp template (CMake)

Quickstart template for GDExtension development with Godot 4.3+, built with CMake.

## Contents
* C++ sources for the extension ([src/](./src/))
* An empty Godot project in [project/](./project) to test the extension
* godot-cpp as a submodule (`godot-cpp/`)
* Class reference XML in [doc_classes/](./doc_classes) (built into debug/editor builds)
* `CMakePresets.json` with parallel debug / release / editor presets

## Setup
```sh
git submodule update --init --recursive
```

Then name the extension. There is a single place to do it: `LIBNAME` in [CMakeLists.txt](./CMakeLists.txt)
(or `-DLIBNAME=my_extension` when configuring). It drives:
* the library file name
* the generated `project/bin/<LIBNAME>.gdextension`, created from [build_schemas/extension.gdextension.in](./build_schemas/extension.gdextension.in)
* the entry symbol (`<LIBNAME>_library_init`, with `-` etc. converted to `_`), passed to [src/register_types.cpp](./src/register_types.cpp) as `GDEXT_ENTRY_SYMBOL`
* `compatibility_minimum` in the `.gdextension`, taken from `GODOT_API_VERSION`

Edit the schema, not the generated file. The generated `.gdextension` is git-ignored; the Godot-created
`<LIBNAME>.gdextension.uid` next to it should be committed. If you rename the extension, delete the old generated files.

## Build
```sh
cmake -B build -DEXT_CXX_STANDARD=23 -DGODOTCPP_TARGET=template_debug
cmake --build build -j
```
Or with presets (these already use all cores):
```sh
cmake --preset debug
cmake --build --preset debug
```
`-j` alone uses all cores, `-j 8` uses eight. Ninja (`-G Ninja`) is parallel by default.

The library is written straight into `project/bin/<platform>/`. Open [project/](./project) in Godot and run the main scene; it should print `Type: 24`.

## Options
| Option | Default | Notes |
|---|---|---|
| `EXT_CXX_STANDARD` | 23 | 17 / 20 / 23 / 26 (minimum 17; 26 needs CMake 3.25+ and a new enough compiler, e.g. GCC 14+) |
| `GODOT_API_VERSION` | 4.3 | Godot API the bindings are generated from (4.3 - 4.7). Keep `compatibility_minimum` in the .gdextension in step |
| `GODOTCPP_TARGET` | template_debug | template_debug / template_release / editor |
| `LIBNAME` | example | Extension name: library, .gdextension and entry symbol all follow it |
| `EXT_ENTRY_SYMBOL` | (derived) | Override the entry symbol if you need a specific one |
| `GODOT_PROJECT_DIR` | project | Godot project folder |
| `GODOTCPP_BUILD_PROFILE` | unset | e.g. `build_profile.json`, to build only the classes you use |

Other `GODOTCPP_*` options (precision, exceptions, ...) belong to godot-cpp; pass them with `-D`.

## IDEs
CMake can export `compile_commands.json`: add `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` when configuring.
