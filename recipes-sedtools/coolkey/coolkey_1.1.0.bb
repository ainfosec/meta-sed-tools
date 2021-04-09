SUMMARY = "Coolkey"
LICENSE = "LGPLv2.1+"
LIC_FILES_CHKSUM = "file://${THISDIR}/../../COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "http://ftp.de.debian.org/debian/pool/main/c/coolkey/coolkey_1.1.0.orig.tar.gz"

SRC_URI[md5sum] = "815a1811a46bf9b8782107c073149cbe"
SRC_URI[sha256sum] = "8448e3abb81bffc593c96b577dcfbc05b40e8684188456c31be15fae73d730f7"

inherit autotools pkgconfig

DEPENDS = "pcsc-lite zlib"
