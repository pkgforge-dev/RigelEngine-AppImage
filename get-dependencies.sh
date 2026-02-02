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
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"
# Determine to build nightly or stable
if [ "${DEVEL_RELEASE-}" = 1 ]; then
	echo "Making nightly build of RigelEngine..."
	# Get the latest tag
    TAG=$(git ls-remote --tags --sort="v:refname" https://github.com/lethal-guitar/RigelEngine | tail -n1 | sed 's/.*\///; s/\^{}//; s/^v//')
    # Get the short hash
    HASH=$(git ls-remote "$REPO" HEAD | cut -c 1-8)
    VERSION="${TAG}-${HASH}"
    git clone --recursive "$REPO" ./RigelEngine
else
	echo "Making stable build of RigelEngine..."
	wget "$GRON" -O ./gron.awk
	chmod +x ./gron.awk
	VERSION=$(wget https://api.github.com/repos/lethal-guitar/RigelEngine/tags -O - | \
		./gron.awk | grep -v "nJoy" | awk -F'=|"' '/name/ {print $3}' | \
		sort -V -r | head -1)
	git clone --branch "$VERSION" --single-branch --recursive "$REPO" ./RigelEngine
fi
echo "$VERSION" > ~/version

#echo "Building nightly build of RigelEngine..."
#echo "---------------------------------------------------------------"

# Get the latest tag
#TAG=$(git ls-remote --tags --sort="v:refname" https://github.com/lethal-guitar/RigelEngine | tail -n1 | sed 's/.*\///; s/\^{}//; s/^v//')
# Get the short hash
#HASH=$(git ls-remote "$REPO" HEAD | cut -c 1-8)
#VERSION="${TAG}-${HASH}"
#git clone --recursive "$REPO" ./RigelEngine
#echo "$VERSION" > ~/version

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
