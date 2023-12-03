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
  #git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_x86_x86_64-linux-android-4.9 -b lineage-19.1 gcc/linux-x86/x86/x86_64-linux-android-4.9
  #git clone --depth=1 https://android.googlesource.com/kernel/prebuilts/build-tools -b android-13.0.0_r0.117 kernel-build-tools
  #git clone --depth=1 https://github.com/LineageOS/android_prebuilts_tools-lineage tools-lineage
  cd -

  # Clone kernel sources and apply patches
  clone_repo() {
    git clone --depth=1 https://github.com/MotorolaMobilityLLC/$1 -b MMI-S1SR32.38-87-2 $2
  }

  apply_p() {
    echo "applying commit $1"
    curl -sL https://github.com/Dhina17/android_kernel_motorola_sm6225/commit/${2}.patch | patch -p 1
    [ $? -ne 0 ] && abort "failed to apply patch"
  }

  clone_repo kernel-msm kernel
  cd kernel

  echo "- applying force load modules patch"
  curl -sL https://gist.githubusercontent.com/HemanthJabalpuri/44e958166e690caec692c915e9ba1309/raw/b8f37c0bdbdf87e3e827e0a3c075253b2ecc7540/force_load_modules.patch | patch -p 1

  apply_p "arch: arm64: dts: Exclude standard dts if vendor dts exists" a7da5d0e2745cf0d9c85b256c88657b0dcbcc1b9
  apply_p "moto-bengal: Enable QCACLD" cb4e143a2526894d8f2813538403da274e461616

  clone_repo vendor-qcom-opensource-wlan-qcacld-3.0 drivers/staging/qcacld-3.0/
  apply_p "drivers: staging: Include qcacld-3.0 source" 53588600c813d33f2fdc0d5ee2ed67a9901195e3
  apply_p "qcacld: nuke Kconfig-based configuration entirely" 1d040c25b85a542d79d87bed52f3846e982b4a2d
  apply_p "qcacld-3.0: Fix compilation due to wrong ifdef guard" 0322b6c1dffe2589bcee43914483f459f77a0f22
  apply_p "qcacld-3.0: Always force user build." bdf3d2850166853712360700477430a6a25620e4
  apply_p "qcacld-3.0: Fix regulatory domain country names." f43d4405b43e91e2632b9c31479c851854b84c53

  clone_repo vendor-qcom-opensource-wlan-qca-wifi-host-cmn drivers/staging/qca-wifi-host-cmn/
  clone_repo vendor-qcom-opensource-wlan-fw-api drivers/staging/fw-api/

  clone_repo vendor-qcom-opensource-audio-kernel techpack/audio/
  apply_p "techpack: audio: Correct symlinks" 6adaad48ced68b45ceb7d4c0bfe03acb88798327
  apply_p "techpack: makefile: do not export all the variables" 4173005c7f620c3c81802a5757423449ec1a72a8
  #apply_p "techpack: audio: Setup build makefiles for bengal" a1b89bb775bb481acc11a9adef40c5f79e1900a6
  cd techpack/audio
  curl -sL https://gist.githubusercontent.com/HemanthJabalpuri/44e958166e690caec692c915e9ba1309/raw/2b7b76211786ab863b091a045534762b82d71575/setup_build_makefiles.patch | patch -p 1
  cd -

  clone_repo kernel-msm-techpack-display techpack/display/
  clone_repo kernel-msm-techpack-video techpack/video/
  clone_repo kernel-msm-techpack-camera techpack/camera/

  clone_repo kernel-devicetree arch/arm64/boot/dts/vendor/
  apply_p "dts: vendor: Don't ignore camera and display dtsi files" b97a5091626722ff0562cc4f26e5424b96c2ece8

  clone_repo kernel-camera-devicetree arch/arm64/boot/dts/vendor/qcom/camera/
  clone_repo kernel-display-devicetree arch/arm64/boot/dts/vendor/qcom/display/
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
  cd kernel/out/arch/arm64/boot
  mv Image.gz $OUTFILE

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
