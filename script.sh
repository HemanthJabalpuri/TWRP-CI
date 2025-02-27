MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp"
MANIFEST_BRANCH="twrp-12.1"
DEVICE_TREE_URL="https://github.com/HemanthJabalpuri/twrp_motorola_devon"
DEVICE_TREE_BRANCH="android-12.1"
DEVICE_PATH="device/motorola/devon"
COMMON_TREE_URL=""
COMMON_PATH=""
BUILD_TARGET="boot"
TW_DEVICE_VERSION="0"

DEVICE_NAME="$(echo $DEVICE_PATH | cut -d "/" -f 3)"
case $MANIFEST_BRANCH in
  twrp-1*) buildtree="twrp";;
  *) buildtree="omni";;
esac
MAKEFILE_NAME="${buildtree}_$DEVICE_NAME"

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
  python3 /usr/local/bin/repo init --depth=1 $MANIFEST_URL -b $MANIFEST_BRANCH

  # Repo Sync
  python3 /usr/local/bin/repo sync -j$(nproc --all) --force-sync || abort "sync error"

  # Apply patches
  #cd bootable/recovery
  #curl -sL https://gist.githubusercontent.com/HemanthJabalpuri/5acb866f9fe11b34e5b469b4500e0769/raw/390ac14d13338fad3775d70b0e696304854cf01a/modules.patch | patch -p 1
  #cd -
  #cd system/core
  #curl -sL https://github.com/HemanthJabalpuri/twrp_motorola_rhode/files/11550608/dontLoadVendorModules.txt | patch -p 1
  #cd -

  # Clone device tree
  git clone $DEVICE_TREE_URL -b $DEVICE_TREE_BRANCH $DEVICE_PATH || abort "ERROR: Failed to Clone the Device Tree!"

  # Clone common tree
  if [ -n "$COMMON_TREE_URL" ] && [ -n "$COMMON_PATH" ]; then
    git clone $COMMON_TREE_URL -b $DEVICE_TREE_BRANCH $COMMON_PATH || abort "ERROR: Failed to Clone the Common Tree!"
  fi
}

syncDevDeps() {
  # Sync Device Dependencies
  depsf=$DEVICE_PATH/${buildtree}.dependencies
  if [ -f $depsf ]; then
    curl -sL https://raw.githubusercontent.com/CaptainThrowback/Action-Recovery-Builder/main/scripts/convert.sh > ~/convert.sh
    bash ~/convert.sh $depsf
    repo sync -j$(nproc --all)
  else
    echo " Skipping, since $depsf not found"
  fi
}

build() {
  export USE_CCACHE=1
  export CCACHE_SIZE="50G"
  export CCACHE_DIR="$HOME/work/.ccache"
  ccache -M ${CCACHE_SIZE}

  # Building recovery
  source build/envsetup.sh
  export ALLOW_MISSING_DEPENDENCIES=true
  lunch ${MAKEFILE_NAME}-eng || abort "ERROR: Failed to lunch the target!"
  export TW_DEVICE_VERSION
  mka -j$(nproc --all) ${BUILD_TARGET}image || abort "ERROR: Failed to Build TWRP!"
}

upload() {
  # Get Version info stored in variables.h
  TW_MAIN_VERSION=$(cat bootable/recovery/variables.h | grep "define TW_MAIN_VERSION_STR" | cut -d \" -f2)
  OUTFILE=TWRP-${TW_MAIN_VERSION}-${TW_DEVICE_VERSION}-${DEVICE_NAME}-$(date "+%Y%m%d%I%M").zip

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

  if [ $BUILD_TARGET = "boot" ]; then
    #git clone --depth=1 https://github.com/HemanthJabalpuri/twrp_abtemplate
    cp -r $WORK_PATH/$DEVICE_PATH/installer twrp_abtemplate
    cd twrp_abtemplate
    cp ../${OUTFILE%.zip}.img .
    zip -r9 $OUTFILE *
  fi
  uploadfile $OUTFILE
}

case "$1" in
  sync|syncDevDeps|build|upload) $1;;
esac
