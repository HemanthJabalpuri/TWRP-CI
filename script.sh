product=rhode
my_top_dir=$PWD

clone_repo() {
  git clone --depth=1 $remote/$1 -b $tag $2
}

tag="android-11.0.0_r48"
remote="https://android.googlesource.com/platform/prebuilts"

mkdir -p $my_top_dir/prebuilts/
cd $my_top_dir/prebuilts/
clone_repo build-tools build-tools
clone_repo gcc/linux-x86/aarch64/aarch64-linux-android-4.9 gcc/linux-x86/aarch64/aarch64-linux-android-4.9
clone_repo gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8 gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8
clone_repo clang/host/linux-x86 clang/host/linux-x86
tag="android-8.1.0_r81"
clone_repo gcc/linux-x86/arm/arm-eabi-4.8 gcc/linux-x86/arm/arm-eabi-4.8
cd -


tag="MMI-S1SRS32.38-132-14"
remote="https://github.com/MotorolaMobilityLLC"

mkdir kernel && cd kernel
clone_repo kernel-msm msm-4.19
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
cd -

mkdir -p $my_top_dir/out/target/product/generic/obj/kernel/msm-4.19 

kernel_out_dir=$my_top_dir/out/target/product/generic/obj/kernel/msm-4.19 
kernel_obj_out_dir=$my_top_dir/out/target/product/generic/obj/KERNEL_OBJ 

make=$my_top_dir/prebuilts/build-tools/linux-x86/bin/make
aarch64_linux_android_=$my_top_dir/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
x86_64_linux_ar=$my_top_dir/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/bin/x86_64-linux-ar
x86_64_linux_ld=$my_top_dir/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/bin/x86_64-linux-ld
clang=$my_top_dir/prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang
arm_eabi_=$my_top_dir/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi- 

cat kernel/msm-4.19/arch/arm64/configs/vendor/bengal-perf_defconfig kernel/msm-4.19/arch/arm64/configs/vendor/ext_config/moto-bengal.config kernel/msm-4.19/arch/arm64/configs/vendor/ext_config/$product-default.config kernel/msm-4.19/arch/arm64/configs/vendor/debugfs.config >> $kernel_out_dir/.config 

$make -j48 -C kernel/msm-4.19 \
  O=$kernel_out_dir \
  DTC_EXT=dtc \
  DTC_OVERLAY_TEST_EXT=ufdt_apply_overlay \
  CONFIG_BUILD_ARM64_DT_OVERLAY=y \
  HOSTCC=$clang \
  HOSTAR=$x86_64_linux_ar \
  HOSTLD=$x86_64_linux_ld \
  ARCH=arm64 \
  CROSS_COMPILE=$aarch64_linux_android_ \
  REAL_CC=$my_top_dir/vendor/qcom/proprietary/llvm-arm-toolchain-ship/10.0/bin/clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  defoldconfig

$make -j48 -C kernel/msm-4.19 \
  'HOSTCFLAGS=-I$my_top_dir/kernel/msm-4.19/include/uapi -I/usr/include -I/usr/include/x86_64-linux-gnu -L/usr/lib -L/usr/lib/x86_64-linux-gnu -fuse-ld=lld' \
  'HOSTLDFLAGS=-L/usr/lib -L/usr/lib/x86_64-linux-gnu -fuse-ld=lld' \
  ARCH=arm64 \
  CROSS_COMPILE=$aarch64_linux_android_ \
  O=$kernel_out_dir \
  REAL_CC=$my_top_dir/vendor/qcom/proprietary/llvm-arm-toolchain-ship/10.0/bin/clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  DTC_EXT=dtc \
  DTC_OVERLAY_TEST_EXT=ufdt_apply_overlay \
  CONFIG_BUILD_ARM64_DT_OVERLAY=y \
  HOSTCC=$clang \
  HOSTAR=$x86_64_linux_ar \
  HOSTLD=$x86_64_linux_ld \
  headers_install

$make -j48 -C kernel/msm-4.19 \
  ARCH=arm64 \
  CROSS_COMPILE=$aarch64_linux_android_ \
  'HOSTCFLAGS=-I$my_top_dir/kernel/msm-4.19/include/uapi -I/usr/include -I/usr/include/x86_64-linux-gnu -L/usr/lib -L/usr/lib/x86_64-linux-gnu -fuse-ld=lld' \
  'HOSTLDFLAGS=-L/usr/lib -L/usr/lib/x86_64-linux-gnu -fuse-ld=lld' \
  O=$kernel_out_dir \
  REAL_CC=$my_top_dir/vendor/qcom/proprietary/llvm-arm-toolchain-ship/10.0/bin/clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  DTC_EXT=dtc \
  DTC_OVERLAY_TEST_EXT=ufdt_apply_overlay \
  CONFIG_BUILD_ARM64_DT_OVERLAY=y \
  HOSTCC=$clang \
  HOSTAR=$x86_64_linux_ar \
  HOSTLD=$x86_64_linux_ld

$make -j48 -C kernel/msm-4.19 \
  O=$kernel_out_dir \
  INSTALL_MOD_STRIP=1 \
  INSTALL_MOD_PATH=$kernel_out_dir/repo/out/target/product/$product/obj/kernel/msm-4.19/staging \
  REAL_CC=$my_top_dir/vendor/qcom/proprietary/llvm-arm-toolchain-ship/10.0/bin/clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  DTC_EXT=dtc \
  DTC_OVERLAY_TEST_EXT=ufdt_apply_overlay \
  CONFIG_BUILD_ARM64_DT_OVERLAY=y \
  HOSTCC=$clang \
  HOSTAR=$x86_64_linux_ar \
  HOSTLD=$x86_64_linux_ld \
  modules_install

$make -C kernel/msm-4.19 \
  O=$kernel_obj_out_dir \
  ARCH=arm64 \
  CROSS_COMPILE=$arm_eabi_ \
  clean

$make -C kernel/msm-4.19 \
  O=$kernel_obj_out_dir \
  ARCH=arm64 \
  CROSS_COMPILE=$arm_eabi_ \
  mrproper

$make -C kernel/msm-4.19 \
  O=$kernel_obj_out_dir \
  ARCH=arm64 \
  CROSS_COMPILE=$arm_eabi_ \
  distclean
