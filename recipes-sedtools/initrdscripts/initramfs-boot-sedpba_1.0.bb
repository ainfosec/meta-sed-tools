DESCRIPTION = "sed-rootfs init script"
SRC_URI = "file://init-boot-sedpba.sh"
PR = "r0"

do_install() {
        install -m 0755 ${WORKDIR}/init-boot-sedpba.sh ${D}/init
}

inherit allarch

FILES_${PN} += " /init "
