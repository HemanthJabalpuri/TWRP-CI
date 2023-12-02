product=rhode
my_top_dir=$PWD

# Clone compilers

mkdir -p $my_top_dir/prebuilts/ && cd $my_top_dir/prebuilts/
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b clang/kernel/linux-x86/clang-r416183b
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 gcc/linux-x86/aarch64/aarch64-linux-android-4.9
#git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-19.1 gcc/linux-x86/arm/arm-linux-androideabi-4.9
#git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_x86_x86_64-linux-android-4.9 -b lineage-19.1 gcc/linux-x86/x86/x86_64-linux-android-4.9
#git clone --depth=1 https://android.googlesource.com/kernel/prebuilts/build-tools -b android-13.0.0_r0.117 kernel-build-tools
#git clone --depth=1 https://github.com/LineageOS/android_prebuilts_tools-lineage tools-lineage
cd -

# Clone kernel sources

clone_repo() {
  git clone --depth=1 $remote/$1 -b $tag $2
}

tag="MMI-S1SRS32.38-132-14"
remote="https://github.com/MotorolaMobilityLLC"

clone_repo kernel-msm kernel
cd kernel
clone_repo vendor-qcom-opensource-wlan-qcacld-3.0 drivers/staging/qcacld-3.0/
clone_repo vendor-qcom-opensource-wlan-qca-wifi-host-cmn drivers/staging/qca-wifi-host-cmn/
clone_repo vendor-qcom-opensource-wlan-fw-api drivers/staging/fw-api/
clone_repo vendor-qcom-opensource-audio-kernel techpack/audio/
clone_repo kernel-msm-techpack-display techpack/display/
clone_repo kernel-msm-techpack-video techpack/video/
clone_repo kernel-msm-techpack-camera techpack/camera/
clone_repo kernel-devicetree arch/arm64/boot/dts/vendor/
clone_repo kernel-camera-devicetree arch/arm64/boot/dts/vendor/qcom/camera/
clone_repo kernel-display-devicetree arch/arm64/boot/dts/vendor/qcom/display/

# Apply patches
apply_p() {
  curl -sL https://github.com/Dhina17/android_kernel_motorola_sm6225/commit/${1}.patch | patch -p 1
}

# techpack: audio: Correct symlinks
apply_p 6adaad48ced68b45ceb7d4c0bfe03acb88798327

# drivers: staging: Include qcacld-3.0 source
apply_p 53588600c813d33f2fdc0d5ee2ed67a9901195e3

# qcacld: nuke Kconfig-based configuration entirely
apply_p 1d040c25b85a542d79d87bed52f3846e982b4a2d

# qcacld-3.0: Fix compilation due to wrong ifdef guard
apply_p 0322b6c1dffe2589bcee43914483f459f77a0f22

# techpack: makefile: do not export all the variables
apply_p 4173005c7f620c3c81802a5757423449ec1a72a8

cat arch/arm64/configs/vendor/bengal-perf_defconfig arch/arm64/configs/vendor/ext_config/moto-bengal.config arch/arm64/configs/vendor/ext_config/${product}-default.config arch/arm64/configs/vendor/debugfs.config > arch/arm64/configs/${product}_defconfig

make O=out ARCH=arm64 ${product}_defconfig

PATH="$my_top_dir/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin:$my_top_dir/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$my_top_dir/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin:${PATH}" \
make -j$(nproc --all) O=out \
  ARCH=arm64 \
  CC=clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  CROSS_COMPILE=aarch64-linux-android- \
  CROSS_COMPILE_ARM32=arm-linux-androideabi-
