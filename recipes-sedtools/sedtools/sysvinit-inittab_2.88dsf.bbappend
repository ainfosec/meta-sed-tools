do_install_append() {

    sed -i 's/\/sbin\/getty 38400 tty1/\/usr\/bin\/sed_tools \/dev\/sda --boot-pba/g' ${D}${sysconfdir}/inittab
	sed -i 's/\/sbin\/getty 38400 tty1/\sbin\/getty 38400 tty/g' ${D}${sysconfdir}/inittab
	#echo "2:23:respawn:/sbin/getty 38400 tty2" >> ${D}${sysconfdir}/inittab    
}
