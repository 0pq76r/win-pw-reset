#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function usage() {
	echo $0 ARCH_ISO
}

function patch() {
	#Unpack and mount x86 32bit image
	unsquashfs airootfs.sfs
	mount squashfs-root/airootfs.img ${mount_dir}

	#Copy script
	cp ${SCRIPT_DIR}/win-root-cmd ${mount_dir}/bin/
	chmod 777 ${mount_dir}/bin/win-root-cmd
	echo /bin/win-root-cmd >> ${mount_dir}/etc/profile

	#Repack
	umount ${mount_dir}
	rm airootfs.sfs -f
	mksquashfs squashfs-root airootfs.sfs 
	md5sum airootfs.sfs > airootfs.md5 
	rm squashfs-root/ -rf
}

function main() {
	if [[ $# != 1 ]]; then
		usage $@
		return;
	fi
	
	mount_dir=$(mktemp -d)
	work_dir=$(mktemp -d)
	
	#Copy ISO content
	mount -o loop,ro $1 ${mount_dir}
	cp -a ${mount_dir}/* ${work_dir}
	umount ${mount_dir}

	#x86 32bit image
	cd ${work_dir}/arch/i686
	patch

	#x86 64bit image
	cd ${work_dir}/arch/x86_64
	patch
	
	#Generate ISO-file
	ISO=arch_custom_$(date +%s).iso
	genisoimage -l -r -V "ARCH_201408" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o ~/${ISO} ${work_dir}
	isohybrid ~/${ISO}
}

main $@
