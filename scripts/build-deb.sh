#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2025-2026 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -euo pipefail

# -- Prepare source.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
PACKAGE_VERSION="${PACKAGE_VERSION:?PACKAGE_VERSION must be supplied by CI}"
TARGET_ARCH="${TARGET_ARCH:-$(dpkg --print-architecture)}"
DEB_HOST_MULTIARCH="${DEB_HOST_MULTIARCH:-$(dpkg-architecture -qDEB_HOST_MULTIARCH)}"

# -- Download Source

git clone --depth 1 --branch "${MAUIKIT_ACCOUNTS_BRANCH}" https://github.com/Nitrux/mauikit-accounts-src.git "$repo_root/mauikit-accounts-src"
source_dir="$repo_root/mauikit-accounts-src"

# -- Configure build.

# MauiKit software must be built with CMake and ECM; never use Meson.
build_dir="$repo_root/build"
cmake_dir="$build_dir/cmake"
stage_dir="$build_dir/package"
rm -rf "$cmake_dir" "$stage_dir"
mkdir -p "$build_dir"

cmake_args=(
    -DCMAKE_INSTALL_PREFIX=/usr
    -DKDE_INSTALL_LIBDIR="lib/$DEB_HOST_MULTIARCH"
    -DCMAKE_BUILD_TYPE=Release
)
if [ "$(dpkg-architecture -qDEB_HOST_ARCH)" = "amd64" ]; then
    cmake_args+=("-DCMAKE_CXX_FLAGS=-march=x86-64-v3")
fi

# -- Compile Source

cmake -S "$source_dir" -B "$cmake_dir" "${cmake_args[@]}"
cmake --build "$cmake_dir" --parallel "$(nproc)"

# -- Install source to DESTDIR.

DESTDIR="$stage_dir" cmake --install "$cmake_dir"

# -- Create DEBIAN control file.

mkdir -p "$stage_dir/DEBIAN"
cat > "$stage_dir/DEBIAN/control" <<CONTROL
Package: mauikit-accounts
Version: ${PACKAGE_VERSION}
Section: libs
Priority: optional
Architecture: ${TARGET_ARCH}
Maintainer: uri_herrera@nxos.org
Provides: mauikit-accounts
Depends: libqt6dbus6,libqt6network6,libqt6quick6,libc6,libkf6configcore6,libkf6coreaddons6,libkf6i18n6,libkf6kiocore6,libqt6core6t64,libqt6qml6,libqt6sql6,mauikit (>= 4.0.4),qml6-module-org-kde-kirigami,qml6-module-qtquick-controls,qml6-module-qtquick-shapes
Description: mauikit-accounts
 mauikit-accounts
CONTROL

# -- Create .deb.

dpkg-deb --build --root-owner-group "$stage_dir" "$build_dir/mauikit-accounts_${PACKAGE_VERSION}_${TARGET_ARCH}.deb"
