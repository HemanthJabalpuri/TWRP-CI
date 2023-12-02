my_top_dir=$PWD

# Clone compilers

mkdir -p $my_top_dir/prebuilts/ && cd $my_top_dir/prebuilts/
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b clang/kernel/linux-x86/clang-r416183b
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 gcc/linux-x86/aarch64/aarch64-linux-android-4.9
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-19.1 gcc/linux-x86/arm/arm-linux-androideabi-4.9
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_x86_x86_64-linux-android-4.9 -b lineage-19.1 gcc/linux-x86/x86/x86_64-linux-android-4.9
git clone --depth=1 https://android.googlesource.com/kernel/prebuilts/build-tools -b android-13.0.0_r0.117 kernel-build-tools
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_tools-lineage tools-lineage
cd -


# Clone kernel sources

git clone --depth=1 https://github.com/LineageOS/android_kernel_motorola_sm6225 kernel


# Build

cd kernel
cat arch/arm64/configs/vendor/bengal-perf_defconfig arch/arm64/configs/vendor/ext_config/moto-bengal.config arch/arm64/configs/vendor/ext_config/rhode-default.config arch/arm64/configs/vendor/debugfs.config > arch/arm64/configs/rhode_defconfig

make O=out ARCH=arm64 rhode_defconfig

PATH="$my_top_dir/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin:$my_top_dir/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$my_top_dir/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin:${PATH}" \
make -j$(nproc --all) O=out \
  ARCH=arm64 \
  CC=clang \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  CROSS_COMPILE=aarch64-linux-android- \
  CROSS_COMPILE_ARM32=arm-linux-androideabi-
