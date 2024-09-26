#!/bin/bash
set -e

# XXX(tom): don't understand why it's needed to set PKG_CONFIG_PATH.
# this directory is already present in pkg-config's config path as reported by
# `pkg-config --variable pc_path pkg-config` in a --debug build environment.
# and yet `pkg-config <some-dependency>` fails
export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH

case "${target_platform}" in
  linux-aarch64|osx-arm64)
    arch="aarch64"
    ;;
  *)
    arch="x86_64"
    ;;
esac
export PSP_ARCH=$arch

pnpm install --filter '@finos/perspective-python'

# Boost!
# Work around boost's inability to detect cxx compiler from $CXX.
# In short: conda provides a compiler binary (compiler('cxx')) on the PATH and
# sets CXX in the environment to point to it. On Linux, the compiler (basename
# $CXX) is called something like x86_64-conda-linux-gnu-g++, and not g++.  This
# conflicts with Boost's bootstrap script, which looks up g++ on the PATH when
# toolchain=gcc is set.
# So on Linux, we have to create a g++ binary on the PATH which point to $CXX.
# NOTE: boost-feedstock does this more rigourously, writing out a
# site-config.jam file and also patching the boost source to give more control
# over the toolchain.  See build.sh and patches/ in
# https://github.com/conda-forge/boost-feedstock/tree/91de9469b5564fd816e4298d217990481c280393/recipe
#
# Would be great if we could just use libboost-headers as a host dependency,
# and not need to build Boost from source and statically link to it.  Thought we
# needed to link Boost for arrow reasons, but arrow-cpp recipe only depends on libboost-headers
# so maybe we can too somehow.
# Note: assumes GNU mktemp, available from coreutils package
# psp_bin=$(mktemp -d -t 'psp-bin-XXXXXX')
# case "${cxx_compiler}" in
#   gxx)
#     cxx_compiler_plus="g++"
#     ;;
#   *)
#     cxx_compiler_plus="${cxx_compiler}"
#   ;;
# esac

# ORIG_PATH=$PATH
# export PATH=$psp_bin:$PATH
# ln -s $CXX $psp_bin/cxx
# ln -s $CXX $psp_bin/$cxx_compiler_plus

# Install boost:
# This configures both the install directory for install_tools.mjs,
# and also the place where FindBoost looks for Boost.
# Note: assumes GNU mktemp
# export Boost_ROOT=$(mktemp -d -t 'psp-boost-root-XXXXXX')
# node tools/perspective-scripts/install_tools.mjs

# PATH=$ORIG_PATH

# Run perspective build
export PACKAGE=perspective-python
export PSP_BUILD_WHEEL=1
pnpm run build

# Install wheel to site-packages ($SP_DIR), wherefrom Conda assembles the .conda package contents
$PYTHON -m pip install rust/target/wheels/perspective_python*.whl -vv


# old recipe:
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
