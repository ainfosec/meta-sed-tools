SUMMARY = "SED Tools live image"
DESCRIPTION = "SED TOOLS live image"
HOMEPAGE = "http://www.ainfosec.com"
DEPENDS = "openssl"
NOHDD="0"
#inherit autotools pkgconfig gettext

S = "${WORKDIR}/git"

SRCREV = "${AUTOREV}"

DEPENDS = "libp11 openssl libtool-cross"

EXTRA_OEMAKE="LIBTOOL=${STAGING_BINDIR_CROSS}/${HOST_SYS}-libtool"

#do_configure_prepend() {
#	cd ${S}
#	ls
#	sleep 10
#	./autogen.sh
#	oe_runconf
#}


#do_compile_prepend() {
#	cd ${S}
#	make
#    oe_runmake
#}

#do_install_prepend() {
#	cd ${S}
#}

do_install_append(){

	install -d ${D}${bindir}
	install -m 0644 ${S}/sed-pba.bin ${D}${bindir}
}

