product=rhode
my_top_dir=$PWD

abort() {
  echo "$1"; exit 1
}

sync() {
  # Clone compilers
  mkdir -p $my_top_dir/prebuilts/ && cd $my_top_dir/prebuilts/
  git clone --depth=1 https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b clang/kernel/linux-x86/clang-r416183b
  git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 gcc/linux-x86/aarch64/aarch64-linux-android-4.9
  git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-19.1 gcc/linux-x86/arm/arm-linux-androideabi-4.9
  cd -

  apply_p() {
    echo "applying commit $1"
    curl -sL https://github.com/Dhina17/android_kernel_motorola_sm6225/commit/${2}.patch | patch -p 1
    [ $? -ne 0 ] && abort "failed to apply patch"
  }

  #cd kernel
  #echo "- applying force load modules patch"
  #curl -sL https://gist.githubusercontent.com/HemanthJabalpuri/44e958166e690caec692c915e9ba1309/raw/4595e439ffd0186a109ab4a631e460545e82e120/force_load.patch | patch -p 1
}


build() {
  cd kernel
  cat arch/arm64/configs/vendor/bengal-perf_defconfig \
      arch/arm64/configs/vendor/ext_config/moto-bengal.config \
      arch/arm64/configs/vendor/ext_config/${product}-default.config \
      arch/arm64/configs/vendor/debugfs.config > arch/arm64/configs/${product}_defconfig

  make O=out ARCH=arm64 ${product}_defconfig

  PATH="$my_top_dir/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin:$my_top_dir/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$my_top_dir/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin:${PATH}" \
  make -j$(nproc --all) O=out \
    ARCH=arm64 \
    CC=clang \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi-
}


upload() {
  OUTFILE=kernel-${product}-$(date "+%Y%m%d%I%M").gz

  # Change to the Output Directory
  #cd kernel/out/arch/arm64/boot
  #mv Image.gz $OUTFILE
  ls -lhR kernel > list.txt

  uploadfile() {
    # Upload to WeTransfer
    # NOTE: the current Docker Image, "registry.gitlab.com/sushrut1101/docker:latest", includes the 'transfer' binary by Default
    curl --upload-file $1 https://free.keep.sh > link.txt || abort "ERROR: Failed to Upload $1!"

    # Mirror to oshi.at
    #TIMEOUT=20160
    #curl -T $1 https://oshi.at/$1/${TIMEOUT} > mirror.txt || echo "WARNING: Failed to Mirror the Build!"

    # Show the Download Link
    DL_LINK=$(cat link.txt)
    #MIRROR_LINK=$(cat mirror.txt | grep Download | cut -d " "  -f 1)
    echo "==$1=="
    echo "Download Link: ${DL_LINK}" || echo "ERROR: Failed to Upload the Build!"
    #echo "Mirror: ${MIRROR_LINK}" || echo "WARNING: Failed to Mirror the Build!"
    echo "=============================================="
    echo " "
  }
  #uploadfile $OUTFILE
  uploadfile list.txt
}


case "$1" in
  sync|build|upload) $1;;
esac
