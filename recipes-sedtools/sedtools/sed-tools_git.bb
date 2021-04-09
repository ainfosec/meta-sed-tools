SUMMARY = "SED Tools"
DESCRIPTION = "SED TOOLS"
HOMEPAGE = "http://www.ainfosec.com"
DEPENDS = "openssl"
NOHDD="0"
inherit autotools pkgconfig gettext


SRC_URI = ""

S = "${WORKDIR}/git"

SRCREV = "${AUTOREV}"

DEPENDS = "libp11 openssl libtool-cross"

EXTRA_OEMAKE="LIBTOOL=${STAGING_BINDIR_CROSS}/${HOST_SYS}-libtool"

do_configure_prepend() {
	cd ${S}
	./autogen.sh
	oe_runconf
}

do_compile_prepend() {
	cd ${S}
	make
    oe_runmake
}

do_install_prepend() {
	cd ${S}
}

