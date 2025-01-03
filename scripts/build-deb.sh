#!/bin/bash

set -eu

### Update sources

mkdir -p /etc/apt/keyrings

curl -fsSL https://packagecloud.io/nitrux/depot/gpgkey | gpg --dearmor -o /etc/apt/keyrings/nitrux_depot-archive-keyring.gpg
curl -fsSL https://packagecloud.io/nitrux/testing/gpgkey | gpg --dearmor -o /etc/apt/keyrings/nitrux_testing-archive-keyring.gpg
curl -fsSL https://packagecloud.io/nitrux/unison/gpgkey | gpg --dearmor -o /etc/apt/keyrings/nitrux_unison-archive-keyring.gpg

cat <<EOF > /etc/apt/sources.list.d/nitrux-depot.list
deb [signed-by=/etc/apt/keyrings/nitrux_depot-archive-keyring.gpg] https://packagecloud.io/nitrux/depot/debian/ trixie main
EOF

cat <<EOF > /etc/apt/sources.list.d/nitrux-testing.list
deb [signed-by=/etc/apt/keyrings/nitrux_testing-archive-keyring.gpg] https://packagecloud.io/nitrux/testing/debian/ trixie main
EOF

cat <<EOF > /etc/apt/sources.list.d/nitrux-unison.list
deb [signed-by=/etc/apt/keyrings/nitrux_unison-archive-keyring.gpg] https://packagecloud.io/nitrux/unison/debian/ trixie main
EOF

apt -q update

### Install Package Build Dependencies #2

apt -q -y install --no-install-recommends \
	mauikit-git

### Download Source

git clone --depth 1 --branch $MAUIKIT_ACCOUNTS_BRANCH https://invent.kde.org/maui/mauikit-accounts.git

rm -rf mauikit-accounts/{LICENSE,README.md}

### Compile Source

mkdir -p build && cd build

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_BSYMBOLICFUNCTIONS=OFF \
	-DQUICK_COMPILER=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LOCALSTATEDIR=/var \
	-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_INSTALL_RUNSTATEDIR=/run "-GUnix Makefiles" \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_INSTALL_LIBDIR=/usr/lib/x86_64-linux-gnu ../mauikit-accounts/

make -j"$(nproc)"

make install

### Run checkinstall and Build Debian Package

>> description-pak printf "%s\n" \
	'A free and modular front-end framework for developing user experiences.' \
	'' \
	'MauiKit utilities to handle User Accounts.' \
	'' \
	'Maui stands for Multi-Adaptable User Interface and allows ' \
	'any Maui app to run on various platforms + devices,' \
	'like Linux Desktop and Phones, Android, or Windows.' \
	'' \
	'This package contains the MauiKit accounts shared library, the MauiKit accounts QML module' \
	'and the MauiKit accounts development headers.' \
	'' \
	''

checkinstall -D -y \
	--install=no \
	--fstrans=yes \
	--pkgname=mauikit-accounts-git \
	--pkgversion=$PACKAGE_VERSION \
	--pkgarch=amd64 \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=libs \
	--pkgsource=mauikit-accounts \
	--pakdir=. \
	--maintainer=uri_herrera@nxos.org \
	--provides=mauikit-accounts-git \
	--requires="libc6,libkf6config6,libkf6coreaddons6,libkf6i18n6,libkf6kio,libqt6core6t64,libqt6qml6,libqt6sql6,mauikit-git \(\>= 4.0.1\),qml6-module-org-kde-kirigami,qml6-module-qtquick-controls,qml6-module-qtquick-shapes" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
