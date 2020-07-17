#!/usr/bin/env bash

#
# Jenkins build script for AOSPA
# Author: Joshua Blanchard (jleeblanch)
# Credits: moto-SDM6xx crew, Lineage Team
#

# Variables set in jenkins environment
# REPO_SYNC
# DEVICE
# BUILDTYPE
# VARIANT
# DISABLE_GAPPS
# PA_SCRIPT
#

# Preset variables
AOSPA_ROOT=/home/jenkins/android/aospa
AOSPA_OUT="$AOSPA_ROOT"/out/target/product
FILE_HOST=/home/jenkins/nginx/AOSPA
CCACHE_EXEC=$(command -v ccache)
ROOMSERVICE="$AOSPA_ROOT"/.repo/local_manifests/roomservice.xml

export KBUILD_BUILD_USER=jleeblanch
export KBUILD_BUILD_HOST=hazard-BoX
export CCACHE_DIR=/home/jenkins/.ccache
export USE_CCACHE=1
export CCACHE_EXEC

if [ "${DISABLE_GAPPS}" == true ]; then
    echo "[+] Disabling GApps..."
    export TARGET_DISABLES_GAPPS=true
fi

echo "[+] Build variables..."
echo KBUILD_BUILD_USER="$KBUILD_BUILD_USER"
echo KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST"
echo USER="$USER"
echo DEVICE="${DEVICE}"
echo BUILDTYPE="${BUILDTYPE}"
echo AOSPA_ROOT="$AOSPA_ROOT"
echo AOSPA_OUT="$AOSPA_OUT"
echo FILE_HOST="$FILE_HOST"
echo CCACHE_DIR="$CCACHE_DIR"
echo CLEAN="${CLEAN}"
echo REPO_SYNC="${REPO_SYNC}"
echo TARGET_DISABLES_GAPPS="${DISABLE_GAPPS}"
echo PA_SCRIPT="${PA_SCRIPT}"

cd "$AOSPA_ROOT" || exit 1 # Bail here if cd fails

if [ "${REPO_SYNC}" == true ]; then
	echo '[+] Syncing repos...'
	# Remove roomservice.xml before sync, we have our own local manifest
	if [ -f "$ROOMSERVICE" ]; then
	    rm -rf "$ROOMSERVICE"
	fi
	repo sync -c --force-sync --no-clone-bundle --no-tags
fi

echo "[+] Setting environment..."
# shellcheck disable=SC1091
. build/envsetup.sh

breakfast pa_"${DEVICE}"-"${BUILDTYPE}"

if [[ "$TARGET_PRODUCT" != pa_* ]]; then
    echo '[+] Breakfast failed, exiting...'
    exit 1
fi

if [ "${CLEAN}" != true ]; then
    echo "[+] Removing zips, images, and staging directories..."
    mka installclean
    rm -rf "$AOSPA_OUT"/"${DEVICE}"/pa-*.zip && \
    rm -rf "$AOSPA_OUT"/"${DEVICE}"/obj/PACKAGING/target_files_intermediates/* && \
    rm -rf "$AOSPA_OUT"/"${DEVICE}"/product && \
    rm -rf "$AOSPA_OUT"/"${DEVICE}"/system && \
    rm -rf "$AOSPA_OUT"/"${DEVICE}"/vendor && \
    rm -rf "$AOSPA_ROOT"/pa-*.zip
else
    echo "[+] Removing entire out directory..."
    mka clobber
    rm -rf "$AOSPA_ROOT"/out && \
    rm -rf "$AOSPA_ROOT"/pa-*.zip
fi

if [ "${PA_SCRIPT}" != true ]; then
    echo "[+] Starting build..."
    # time mka bootimage
    time mka bacon
else
    echo "[+] Starting PA custom build script..."
    ./rom-build.sh "${DEVICE}" -t "${BUILDTYPE}" -v "${VARIANT}"
fi

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    echo "[+] Build completed successfully..."
    ls "$AOSPA_OUT"/"${DEVICE}"/pa-*-"${DEVICE}"-*.zip

    echo "[+] Copying build to downloads..."
    cp -v "$AOSPA_OUT"/"${DEVICE}"/pa-*-"${DEVICE}"-*.zip "$FILE_HOST"/"${DEVICE}"/
else
    echo "[+] Bruh, you have failed this city..."
    exit 1
fi
exit 0
