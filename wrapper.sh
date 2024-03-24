#!/usr/bin/env bash

dir=$(readlink -f "$(dirname "$0")")
exe=$(basename "$0")

export TMPDIR=/tmp
export COMPILER_PATH=$dir/BIN
export LIBRARY_PATH=$dir/LIB
export PSYQ_PATH=$dir/BIN
export C_INCLUDE_PATH=$dir/INCLUDE
export CPLUS_INCLUDE_PATH=$dir/INCLUDE

exec "$dir/wibo" "$dir/BIN/${exe^^}.EXE" "$@"
