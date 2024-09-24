#!/bin/bash
set -e

# XXX(tom): don't understand why it's needed to set PKG_CONFIG_PATH.
# this directory is already present in pkg-config's config path as reported by
# `pkg-config --variable pc_path pkg-config` in a --debug build environment
export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH
export PACKAGE=perspective-python
export PSP_BUILD_WHEEL=1

case "${target_platform}" in
  linux-aarch64|osx-arm64)
    arch="aarch64"
    ;;
  *)
    arch="x86_64"
    ;;
esac
export PSP_ARCH=$arch

# patch package.json to remove postinstall scripts
# playwright browsers can't be installed, and aren't needed anyway
pnpm pkg set scripts.postinstall:playwright="echo no-postinstall:playwright"
# vscode + emsdk aren't needed
pnpm pkg set scripts.postinstall:vscode="echo no-postinstall:vscode"
pnpm pkg set scripts.postinstall:emsdk="echo no-postinstall:emsdk"

# Boost!
# Work around Boost bootstrap script's inability to detect cxx compiler
# on Linux.
# In short: conda provides the compiler as CXX in the environment.
# It does not, however, provide `g++` on the PATH, at least on Linux.
# (The conda environment does provide a `clang++` binary on the PATH on macOS).
# Boost's bootstrap script looks for a suitably-named compiler on the PATH to
# determine its toolchain, so we have to create those binaries
# Note: assumes GNU mktemp
psp_bin=$(mktemp -d -t 'psp-bin-XXXXXX')
export PATH=$psp_bin:$PATH
case "${cxx_compiler}" in
  gxx)
    cxx_compiler_plus="g++"
    ln -s $CXX $psp_bin/$cxx_compiler_plus
    ;;
  *)
    cxx_compiler_plus="${cxx_compiler}"
  ;;
esac

# XXX(tom): workaround maturin using wrong python??
#
echo "$$PYTHON is: $PYTHON"

# XXX(tom): move me into a patch
# remove lint from workspace - parsing lint's Cargo.toml file requires nightly
# features, and we are building with a stable toolchain
sed -e '/.*rust\/lint.*/d' -i'.backup' Cargo.toml

pnpm install --filter '!@finos/perspective-bench'

# XXX(tom): workaround maturin using wrong python??
#
echo "$$PYTHON is: $PYTHON"

# XXX(tom): move me into a patch
# remove lint from workspace - parsing lint's Cargo.toml file requires nightly
# features, and we are building with a stable toolchain
sed -e '/.*rust\/lint.*/d' -i'.backup' Cargo.toml

pnpm install --filter '!@finos/perspective-bench'

# Install boost:
# This configures both the install directory for install_tools.mjs,
# and also the place where FindBoost looks for Boost.
# Note: assumes GNU mktemp
# export Boost_ROOT=$(mktemp -d -t 'psp-boost-root-XXXXXX')
# node tools/perspective-scripts/install_tools.mjs
pnpm run build

$PYTHON -m pip install rust/target/wheels/perspective_python*.whl -vv

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
