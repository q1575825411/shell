#!/bin/bash
set -eo pipefail

# only true for sunmi baseline
export SUNMI_BASELINE=true

if [[ " true " == " ${BUILD_EFUSE} " ]]; then
	export SUNMI_SECUREBOOT_HSM=true
fi

function build_qssi()
{(
	cd ./QSSI.13/
	if [ -z $APP_PATH ]; then
		APP_PATH=T3_Pro/Sunmi/Release
	fi
	./sunmi_projects/Init-Vendor-S.sh $APP_PATH true
	source build/envsetup.sh
	lunch qssi-userdebug
	bash build.sh $j_arg dist --qssi_only
)}

function build_qssi_user()
{(
	cd ./QSSI.13/
	if [ -z $APP_PATH ]; then
		APP_PATH=T3_Pro/Sunmi/Release
	fi
	./sunmi_projects/Init-Vendor-S.sh $APP_PATH true
	source build/envsetup.sh
	lunch qssi-user
	bash build.sh $j_arg dist --qssi_only
)}

function build_target()
{(
	cd ./UM.9.14/
	source build/envsetup.sh
	lunch lahaina-userdebug
	bash build.sh $j_arg dist --target_only
)}

function build_target_user()
{(
	cd ./UM.9.14/
	source build/envsetup.sh
	lunch lahaina-user
	bash build.sh $j_arg dist --target_only KERNEL_DEFCONFIG=vendor/lahaina-qgki_defconfig
)}

function build_super()
{(
	cd ./UM.9.14/
	python vendor/qcom/opensource/core-utils/build/build_image_standalone.py \
	    --image super \
	    --qssi_build_path ../QSSI.13/ \
	    --target_build_path ./ \
	    --merged_build_path ./ \
	    --target_lunch lahaina \
	    --output_ota
)}

function build_amss()
{(
	cd ./UM.9.14/

	mkdir -p amss/LINUX/android/
	ln -rvsfT out amss/LINUX/android/out

	(
		cd amss
		export BUILDROOT="$(pwd)/boot_images"
		export SECTOOLS_DIR="$(pwd)/common/sectools"
		python boot_images/boot_tools/buildex.py -t kodiak,QcomToolsPkg -v LAA -r RELEASE
	)

	(
		cd amss/common/build
		export BUILDROOT="$(pwd)/boot_images"
		export SECTOOLS_DIR="$(pwd)/common/sectools"
		python2 build.py --variant lahaina
	)
)}


### huyanwei {
function build_pre_secureboot()
{(
	if [ "X${SUNMI_SECUREBOOT_HSM}" != "Xtrue" ] ; then
		echo "build normal version";
	   return 0;
	fi

	echo "pre secure boot";

	cd ./UM.9.14/

	mkdir -p amss/LINUX/android/
	ln -rvsfT out amss/LINUX/android/out

	cd -

	(
		# base env
		BP_BASE_PATH=UM.9.14/amss/
		PREBUILT_PATH=UM.9.14/vendor/qcom/proprietary/prebuilt_HY11/target/product/lahaina/vendor/firmware/
		LOCAL_TARGET_PATH=UM.9.14/amss/LINUX/android/out/target/product/lahaina/vendor/firmware/
		mkdir -p UM.9.14/out/target/product/lahaina/vendor/firmware/

		### sec.elf
		echo "gen sec.elf ..."
		cd ${BP_BASE_PATH} && ./common/build_kodiak_qcm6490_secboot.sh sec.elf && cd -

		### ZAP
		echo "Signing zap ..."
		cd ${PREBUILT_PATH} && git checkout -- a660_zap* && cd - && cp ${PREBUILT_PATH}a660_zap* ${LOCAL_TARGET_PATH}
		cd ${BP_BASE_PATH} && ./common/build_kodiak_qcm6490_secboot.sh zap && cd -
		cp ${BP_BASE_PATH}/common/sectools/secimage_output/kodiak/gfx_microcode/a660_zap* ${PREBUILT_PATH}

		### ADSP
		echo "Signing adsp ..."
		cd ${BP_BASE_PATH} && ./common/build_kodiak_qcm6490_secboot.sh adsp && cd -
		cp ${BP_BASE_PATH}/common/sectools/secimage_output/kodiak/adsp/adsp.* ${PREBUILT_PATH}

		### VENUS
		echo "Signing venus ..."
		cd ${PREBUILT_PATH} && git checkout -- vpu20_1v.mbn  && cd - && cp ${PREBUILT_PATH}vpu20_1v.mbn ${LOCAL_TARGET_PATH}
		cd ${BP_BASE_PATH} && ./common/build_kodiak_qcm6490_secboot.sh venus && cd -
		cp ${BP_BASE_PATH}/common/sectools/secimage_output/kodiak/venus/vpu20_1v.* ${PREBUILT_PATH}
	)
)}

function build_post_secureboot()
{(
	if [ "X${SUNMI_SECUREBOOT_HSM}" != "Xtrue" ] ; then
	   echo "build normal version";
	   return 0;
	fi

	echo "post secure boot ";

	cd ./UM.9.14/

	mkdir -p amss/LINUX/android/
	ln -rvsfT out amss/LINUX/android/out

	cd -

	(
		# base env
		BP_BASE_PATH=UM.9.14/amss/

		# AP+BP
		echo "Signing all ..."
		cd ${BP_BASE_PATH} && ./common/build_kodiak_qcm6490_secboot.sh && cd -
	)
)}

### huyanwei }

function update_target()
{(
	cd ./UM.9.14/

	buildDateUTC=$(grep -E "ro.build.date.utc=" "../QSSI.13/out/target/product/qssi/system/build.prop" | tail -n 1 | cut -d "=" -f2 | tr -d " ")
	echo "buildDateUTC=${buildDateUTC}"
	buildDate=$(date -u --date=@"${buildDateUTC}" +%Y%m%d%H%M%S)

	arrBuildName+=("H2PRO-S" "RexOS")

	if [[ " true " == " ${BUILD_EFUSE} " ]]; then
		arrBuildName+=("efuse")
	fi

	arrBuildName+=("${buildVariant}")

	if [[ -n "${VERSION_NAME}" ]]; then
		arrBuildName+=("${VERSION_NAME}")
	else
		arrBuildName+=("0.0.1")
	fi

	if [[ -n "${BUILD_NUMBER}" ]]; then
		arrBuildName+=("${BUILD_NUMBER}")
	else
		arrBuildName+=("1")
	fi

	arrBuildName+=("${buildDate}")

	for val in "${arrBuildName[@]}"; do
		TARGET_PACKAGE_NAME="${TARGET_PACKAGE_NAME:+${TARGET_PACKAGE_NAME}_}${val}"
	done

	rm -rf out/images/
	mkdir -p out/images/lahaina_unsparse
	mkdir -p out/images/lahaina_symbols

	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/gpt_main[0-9].bin
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/gpt_backup[0-9].bin

	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/asic/sparse_images/super_*.img
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/asic/sparse_images/userdata_*.img
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/asic/sparse_images/metadata_*.img
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/asic/sparse_images/rawprogram_unsparse*.xml
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/asic/sparse_images/rawprogram*.xml.bak

	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/abl.elf
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/boot.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/dtbo.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/persist.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/vbmeta.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/vbmeta_system.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/vendor_boot.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/splash.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/smconf.img
	cp -rvf -t out/images/lahaina_unsparse out/target/product/lahaina/hwconf.img

	cp -rvf -t out/images/lahaina_unsparse amss/common/config/ufs/provision/*.xml
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/rawprogram[1-9].xml
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/patch[0-9].xml
	cp -rvf -t out/images/lahaina_unsparse amss/boot_images/boot/QcomPkg/SocPkg/Kodiak/Bin/LAA/RELEASE/xbl.elf
	cp -rvf -t out/images/lahaina_unsparse amss/boot_images/boot/QcomPkg/SocPkg/Kodiak/Bin/LAA/RELEASE/xbl_config.elf
	cp -rvf -t out/images/lahaina_unsparse amss/aop_proc/build/ms/bin/AAAAANAZO/kodiak/aop.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/trustzone_images/build/ms/bin/IAGAANAA/tz.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/trustzone_images/build/ms/bin/IAGAANAA/hypvm.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/asic/NON-HLOS.bin
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/ufs/bin/BTFM.bin
	# no signed
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/bin/dspso.bin
	cp -rvf -t out/images/lahaina_unsparse amss/qtee_tas/build/ms/bin/IAGAANAA/km41.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/trustzone_images/build/ms/bin/IAGAANAA/devcfg.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/common/core_qupv3fw/kodiak/qupv3fw.elf
	cp -rvf -t out/images/lahaina_unsparse amss/qtee_tas/build/ms/bin/IAGAANAA/uefi_sec.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/boot_images/boot/QcomPkg/SocPkg/Kodiak/Bin/LAA/RELEASE/imagefv.elf
	cp -rvf -t out/images/lahaina_unsparse amss/boot_images/boot/QcomPkg/SocPkg/Kodiak/Bin/LAA/RELEASE/shrm.elf
	# cp -rvf -t out/images/lahaina_unsparse amss/common/build/bin/multi_image/kodiak/multi_image/multi_image.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/bin/multi_image.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/cpucp_proc/kodiak/cpucp/cpucp.elf
	cp -rvf -t out/images/lahaina_unsparse amss/qtee_tas/build/ms/bin/IAGAANAA/featenabler.mbn
	cp -rvf -t out/images/lahaina_unsparse amss/common/build/bin/apdp/apdp.mbn
	# no signed
	cp -rvf -t out/images/lahaina_unsparse amss/boot_images/boot/QcomPkg/Tools/binaries/logfs_ufs_8mb.bin
	cp -rvf -t out/images/lahaina_unsparse amss/qtee_tas/build/ms/bin/IAGAANAA/storsec.mbn

	# no signed
	cp -rvf -t out/images/lahaina_unsparse amss/trustzone_images/build/ms/bin/IAGAANAA/rtice.mbn
	if [[ " true " == " ${BUILD_EFUSE} " ]]; then
		# 熔断版本重命名firehose，防止开发时非熔断设备直接误刷熔断版本
		cp -rvf amss/common/sectools/secimage_output/kodiak/prog_firehose_ddr/prog_firehose_ddr_efuse.elf out/images/lahaina_unsparse/prog_firehose_Qcm6490_ddr_efuse.elf
	else
		cp -rvf amss/boot_images/boot/QcomPkg/SocPkg/Kodiak/Bin/LAA/RELEASE/prog_firehose_ddr.elf out/images/lahaina_unsparse/prog_firehose_Qcm6490_ddr.elf
	fi

	if [[ " true " == " ${BUILD_EFUSE} " ]]; then
		# sec.elf
		cp -rvf -t out/images/lahaina_unsparse amss/common/sectools/fuseblower_output/v2/sec.elf
		# 修改secdata刷机文件
		sed -i "s/filename=\"\" label=\"secdata\"/filename=\"sec.elf\" label=\"secdata\"/g" out/images/lahaina_unsparse/rawprogram*.xml
	fi

	# symbols
	cp -rvf -t out/images/lahaina_symbols out/target/product/lahaina/obj/KERNEL_OBJ/vmlinux

	(
		if command -v 7z > /dev/null 2>&1; then
			7z a -tzip -r -slp -ssc -mmt -bt -snh -snl "./out/images/${TARGET_PACKAGE_NAME}.zip" "./out/images/lahaina_unsparse/*"
		else
			cd out/images/lahaina_unsparse || exit
			zip "../${TARGET_PACKAGE_NAME}.zip" -r -9 .
		fi
	)

	(
		if command -v 7z > /dev/null 2>&1; then
			7z a -tzip -r -slp -ssc -mmt -bt -snh -snl "./out/images/${TARGET_PACKAGE_NAME}_symbols.zip" "./out/images/lahaina_symbols/*"
		else
			cd out/images/lahaina_symbols || exit
			zip "../${TARGET_PACKAGE_NAME}_symbols.zip" -r -9 .
		fi
	)

	cp -rvf out/dist/merged-qssi_lahaina-target_files.zip "out/images/${TARGET_PACKAGE_NAME}_target_files.zip"
	cp -rvf out/dist/merged-qssi_lahaina-ota.zip "out/images/${TARGET_PACKAGE_NAME}_full_ota.zip"
)}

build_type="--all"
# j_arg="-j36"
buildVariant="userdebug"

while [ $# -gt 0 ];do
	case "$1" in
		"--qssi"|"--target"|"--super"|"--all"|"--user")
			build_type=$1
			;;
		"-j"[0-64]*)
			j_arg=$1
			;;
	esac
	case "$2" in
		"-j"[0-64]*)
			j_arg=$2
			;;
	esac
	shift
done

echo $0 "$build_type" "$j_arg"
# huyanwei {
build_pre_secureboot
# huyanwei }

case "$build_type" in
	"--qssi")
		build_qssi $j_arg
		;;
	"--target")
		build_target $j_arg
		;;
	"--super")
		build_super
		;;
	"--all")
		build_qssi $j_arg
		build_target $j_arg
		build_super
		;;
	"--user")
		build_qssi_user $j_arg
		build_target_user $j_arg
		build_super
		buildVariant="user"
		;;
esac

build_amss
# huyanwei {
build_post_secureboot
# huyanwei }
update_target
