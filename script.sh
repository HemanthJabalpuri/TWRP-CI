BUILD_TARGET="boot"
DEVICE_NAME="rhode"

##
abort() { echo "$1"; exit 1; }
WORK_PATH="$HOME/work" # Full (absolute) path.
[ -e $WORK_PATH ] || mkdir $WORK_PATH
cd $WORK_PATH
##

sync() {
  # Install repo
  mkdir ~/bin
  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
  chmod a+x ~/bin/repo
  sudo ln -sf ~/bin/repo /usr/bin/repo
  sudo ln -sf ~/bin/repo /usr/local/bin/repo

  # Initialize repo
  python3 /usr/local/bin/repo init --depth=1 --no-repo-verify -u https://github.com/HemanthJabalpuri/android.git -b lineage-20.0 -g default,-mips,-darwin,-notdefault

  git clone https://github.com/HemanthJabalpuri/local_manifest --depth 1 -b rhode .repo/local_manifests

  # Repo Sync
  python3 /usr/local/bin/repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j8 || abort "sync error"
}

build() {
  export USE_CCACHE=1
  export CCACHE_SIZE="50G"
  export CCACHE_DIR="$HOME/work/.ccache"
  ccache -M ${CCACHE_SIZE}

  # Building recovery
  source build/envsetup.sh
  export ALLOW_MISSING_DEPENDENCIES=true
  lunch lineage_rhode-userdebug || abort "ERROR: Failed to lunch the target!"
  mka -j$(nproc --all) ${BUILD_TARGET}image || abort "ERROR: Failed to Build TWRP!"
}

upload() {
  # Get Version info stored in variables.h
  OUTFILE=lineage-boot-${DEVICE_NAME}-$(date "+%Y%m%d%I%M").zip

  # Change to the Output Directory
  cd out/target/product/$DEVICE_NAME
  mv ${BUILD_TARGET}.img ${OUTFILE%.zip}.img
  zip -r9 $OUTFILE ${OUTFILE%.zip}.img

  uploadfile() {
    # Upload to WeTransfer
    # NOTE: the current Docker Image, "registry.gitlab.com/sushrut1101/docker:latest", includes the 'transfer' binary by Default
    curl --upload-file $1 https://free.keep.sh > link.txt || abort "ERROR: Failed to Upload $1!"

    # Mirror to oshi.at
    TIMEOUT=20160
    curl -T $1 https://oshi.at/$1/${TIMEOUT} > mirror.txt || echo "WARNING: Failed to Mirror the Build!"

    # Show the Download Link
    DL_LINK=$(cat link.txt)
    MIRROR_LINK=$(cat mirror.txt | grep Download | cut -d " "  -f 1)
    echo "==$1=="
    echo "Download Link: ${DL_LINK}" || echo "ERROR: Failed to Upload the Build!"
    echo "Mirror: ${MIRROR_LINK}" || echo "WARNING: Failed to Mirror the Build!"
    echo "=============================================="
    echo " "
  }

  uploadfile $OUTFILE
}

case "$1" in
  sync|build|upload) $1;;
esac
