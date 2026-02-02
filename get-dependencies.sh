#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    cmake      \
    libdecor   \
    sdl2_mixer

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
make-aur-package sdl2

# If the application needs to be manually built that has to be done down here

echo "Building RigelEngine..."
echo "---------------------------------------------------------------"
REPO="https://github.com/lethal-guitar/RigelEngine"
# Determine to build nightly or stable
#if [ "${DEVEL_RELEASE-}" = 1 ]; then
	echo "Making nightly build of RigelEngine..."
	# Get the latest tag
    TAG=$(git ls-remote --tags --sort="v:refname" https://github.com/lethal-guitar/RigelEngine | tail -n1 | sed 's/.*\///; s/\^{}//; s/^v//')
    # Get the short hash
    HASH=$(git ls-remote "$REPO" HEAD | cut -c 1-8)
    VERSION="${TAG}-${HASH}"
    git clone --recursive "$REPO" ./RigelEngine
#else 
#stable is having issues upstream to compile
#	echo "Making stable build of RigelEngine..."
#	VERSION="$(git ls-remote --tags --sort="v:refname" https://github.com/lethal-guitar/RigelEngine | tail -n1 | sed 's/.*\///; s/\^{}//; s/^v//')"
#	git clone --branch v"$VERSION" --single-branch --recursive "$REPO" ./RigelEngine
#fi
echo "$VERSION" > ~/version

cd ./RigelEngine
mkdir -p build 
cd build
cmake .. -Wno-dev -DBUILD_TESTS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(nproc)

mkdir -p "/usr/bin"
cp "src/RigelEngine" "/usr/bin"
# copy over the destop file from the dist directory
mkdir -p "/usr/share/applications"
cp ../dist/linux/rigelengine.desktop "/usr/share/applications"
# copy over the icons from the dist directory
mkdir -p "/usr/share/icons"
cp ../dist/linux/rigelengine_128.png "/usr/share/icons"
# add icon path to the desktop entry
echo Icon=/usr/share/icons/rigelengine_128.png >> "/usr/share/applications/rigelengine.desktop"
