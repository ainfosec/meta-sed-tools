DESCRIPTION = "SED ROOTFS"

IMAGE_FSTYPES = "live"

inherit core-image

IMAGE_INSTALL = " \
	packagegroup-core-boot \
	opensc \
    sed-tools \
	grub \
	openssl \
	pcsc-lite \
	"
IMAGE_LINGUAS = " "

IMAGE_ROOTFS_SIZE = "8192"
SYSLINUX_KERNEL_ARGS_append = "root=/dev/ram rw selinux=0 libata.allow_tpm=1 quiet"
