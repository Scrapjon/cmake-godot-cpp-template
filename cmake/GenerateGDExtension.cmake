# Run in script mode by the build (cmake -P) to write the .gdextension from its schema.
# Expects: SCHEMA, OUTPUT, LIBNAME, EXT_ENTRY_SYMBOL, EXT_COMPAT_MIN
configure_file("${SCHEMA}" "${OUTPUT}" @ONLY)
