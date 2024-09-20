#!/bin/bash
set -e

# XXX(tom): don't understand why it's needed to set PKG_CONFIG_PATH.
# this directory is already present in pkg-config's config path as reported by
# `pkg-config --variable pc_path pkg-config` in a --debug build environment
export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH
export PACKAGE=perspective-python
export PSP_BUILD_WHEEL=1

export CARGO_FEATURE_EXTERNAL_CPP=1
export CARGO_FEATURE_EXTERNAL_PROTO=1

# patch package.json
# playwright browsers can't be installed, and aren't needed anyway
pnpm pkg set scripts.postinstall:playwright="echo no-postinstall:playwright"
# vscode isn't needed
pnpm pkg set scripts.postinstall:vscode="echo no-postinstall:vscode"

# remove lint from workspace - parsing lint's Cargo.toml file requires nightly
# features, and we are building with a stable toolchain
sed -e '/.*rust\/lint.*/d' -i'.backup' Cargo.toml

pnpm install --filter !@finos/perspective-bench
# XXX(tom): TODO: unset cargo feature so as to not use ABI3
pnpm run build

# export CARGO_FEATURE_EXTERNAL_CPP=1
# export PSP_ROOT_DIR=$SRC_DIR/perspective-cpp
# cd perspective_python-${PKG_VERSION}
# cp -r ../perspective_python-${PKG_VERSION}.data .
# cd rust/perspective-client
# export CARGO_FEATURE_EXTERNAL_PROTO=1
# cargo build
# cd ../../
# unset CARGO_FEATURE_EXTERNAL_PROTO
# ${PYTHON} -m pip install . -vv
# ${PYTHON} ${RECIPE_DIR}/copy.py
