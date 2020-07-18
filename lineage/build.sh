#!/usr/bin/env bash

#
# Jenkins build script for LineageOS
# Author: Joshua Blanchard (jleeblanch)
# Credits: moto-SDM6xx crew, Lineage Team
#

# Variables set in Jenkins environment
# REPO_SYNC
# DEVICE
# BUILDTYPE
# CLEAN
#

# Preset variables
LINEAGE_ROOT=/home/jenkins/android/lineage
LINEAGE_OUT="$LINEAGE_ROOT"/out/target/product
FILE_HOST=/home/jenkins/nginx
CCACHE_EXEC=$(command -v ccache)

export KBUILD_BUILD_USER=jleeblanch
export KBUILD_BUILD_HOST=hazard-BoX
export CCACHE_DIR=/home/jenkins/.ccache
export USE_CCACHE=1
export CCACHE_EXEC

echo "[+] Build variables..."
echo KBUILD_BUILD_USER="$KBUILD_BUILD_USER"
echo KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST"
echo USER="$USER"
echo DEVICE="${DEVICE}"
echo BUILDTYPE="${BUILDTYPE}"
echo LINEAGE_ROOT="$LINEAGE_ROOT"
echo CCACHE_DIR="$CCACHE_DIR"
echo CLEAN="${CLEAN}"
echo REPO_SYNC="${REPO_SYNC}"

cd "$LINEAGE_ROOT" || exit 1

if [[ "${REPO_SYNC}" == true ]]; then
	echo '[+] Syncing repos...'
	repo sync -c --force-sync --no-clone-bundle --no-tags
fi

echo "[+] Setting environment..."
# shellcheck disable=SC1091
. build/envsetup.sh

breakfast lineage_"${DEVICE}"-"${BUILDTYPE}"

if [[ "$TARGET_PRODUCT" != lineage_* ]]; then
    echo '[+] Breakfast failed, exiting...'
    exit 1
fi

if [[ "${CLEAN}" != true ]]; then
    echo "[+] Removing zips, images, and staging directories..."
    mka installclean
    rm -rf "$LINEAGE_OUT"/"${DEVICE}"/lineage*.zip && \
    rm -rf "$LINEAGE_OUT"/"${DEVICE}"/obj/PACKAGING/target_files_intermediates/* && \
    rm -rf "$LINEAGE_OUT"/"${DEVICE}"/product && \
    rm -rf "$LINEAGE_OUT"/"${DEVICE}"/system && \
    rm -rf "$LINEAGE_OUT"/"${DEVICE}"/vendor
else
    echo "[+] Removing entire out directory..."
    mka clobber
    rm -rf "$LINEAGE_ROOT"/out
fi

echo "[+] Starting build..."
# time mka bootimage
time mka bacon

# shellcheck disable=SC2181
if [[ $? -eq 0 ]]; then
    echo "[+] Build completed successfully..."
    ls "$LINEAGE_OUT"/"${DEVICE}"/lineage-*.zip

    echo "[+] Copying build to downloads..."
    cp -v "$LINEAGE_OUT"/"${DEVICE}"/lineage-*.zip "$FILE_HOST"/LineageOS/"${DEVICE}"/
    #cp -v "$LINEAGE_OUT"/"${DEVICE}"/lineage-*.md5sum "$FILE_HOST"/LineageOS/"${DEVICE}"/
else
    echo "[+] Bruh, you have failed this city..."
    exit 1
fi
exit 0
