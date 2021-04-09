#!/bin/sh -x

PATH=/sbin:/bin:/usr/sbin:/usr/bin
ROOT_MOUNT=/mnt/root
ROOT_IMAGE_PCR=9
IP=$(which ip)
LN=$(which ln)
MKDIR=$(which mkdir)
MKNOD=$(which mknod)
MKTEMP=$(which mktemp)
MODPROBE=$(which modprobe)
MOUNT=$(which mount)
SLEEP=$(which sleep)

[ -z "$CONSOLE" ] && CONSOLE="/dev/console"

# debug logging failure sequence
#   give access to a shell
fatal() {
    echo $1 >$CONSOLE
    echo >$CONSOLE
    sh
}
# production logging failure sequence (no shell)
fatal_prod() {
    echo $1 >$CONSOLE
    echo >$CONSOLE
}

# sanity
[ ! -x $IP ]       && fatal "No ip command."
[ ! -x $LN ]       && fatal "No ln command."
[ ! -x $MKDIR ]    && fatal "No mkdir command."
[ ! -x $MKNOD ]    && fatal "No mknod command."
[ ! -x $MKTEMP ]   && fatal "No mktemp command."
[ ! -x $MODPROBE ] && fatal "No modprobe command."
[ ! -x $MOUNT ]    && fatal "No mount command."
[ ! -x $SLEEP ]    && fatal "No sleep command."

early_setup () {
    $MKDIR /proc /sys
    $MOUNT -t proc proc /proc
    $MOUNT -t sysfs sysfs /sys

    $MKDIR /tmp /run
    $LN -s /run /var/run
}

tss_setup () {
    $MODPROBE tpm-tis
    # tcsd needs loopback networking
    if ! $IP addr add 127.0.0.1/8 dev lo ; then
        fatal "failed to give loopback a localhost address"
    fi
    if ! $IP link set up dev lo ; then
        fatal "failed to bring up loopback device"
    fi
    # get udev rules executed. we care about tpm & removable media
    if ! /etc/init.d/udev start ; then
        fatal "failed to start udev"
    fi
    # run tcsd
    if ! /etc/init.d/trousers start ; then
        echo "failed to start tcsd"; sleep 2
    fi
}

read_args() {
    [ -z "$CMDLINE" ] && CMDLINE=`cat /proc/cmdline`
    for arg in $CMDLINE; do
        optarg=`expr "x$arg" : 'x[^=]*=\(.*\)'`
        case $arg in
            ro)
                ROOT_MODE=$arg ;;
            rw)
                ROOT_MODE=$ARG ;;
            root=*)
                ROOT_DEVICE=$optarg ;;
            rootimg=*)
                ROOT_IMAGE=$optarg ;;
            rootimgpcr=*)
                ROOT_IMAGE_PCR=$optarg ;;
            console=*)
                if [ -z "${console_params}" ]; then
                    console_params=$arg
                else
                    console_params="$console_params $arg"
                fi
        esac
    done
}

# parameter is name of rootfs image
#   sets ROOT_IMAGE_PATH variable with absolute path to rootfs image
find_rootimg() {
    local rootimg=$1
    [ -z $rootimg ] && fatal "No image for root file system provided."

    echo "Searching for $rootimg in removable media ..."
    for i in $(seq 1 5); do
        for device in `ls /media 2>/dev/null`; do
            if [ -f /media/$device/$rootimg ] ; then
                ROOT_IMAGE_PATH=/media/$device/$rootimg
                echo "found root image: $ROOT_IMAGE_PATH"
                break
            fi
        done
        [ ! -z $ROOT_IMAGE_PATH ] && break
        echo "No image found on iteration $i ..."
        $SLEEP 1
    done
    [ -z $ROOT_IMAGE_PATH ] && fatal "could not find root image: $rootimg"
}

# mount supplied fs image on supplied directory
#   fs image is mounted read only, a tmpfs is created as well
#   the two are mounted in a unionfs with the tmpfs acting as a sort-of COW
mount_rootimg() {
    local root_img=$1
    local root_mnt=$2
    local loop_dev=/dev/loop0
    local cow_mnt=/mnt/cow
    local rootro_mnt=/mnt/root-ro

    [ -z $root_img ] && fatal "no image file passed to mount_rootimg"
    [ -z $root_mnt ] && fatal "no mount point passed to mount_rootimg "

    [ ! -d $root_mnt ]   && $MKDIR -p $root_mnt
    [ ! -d $cow_mnt ]    && $MKDIR -p $cow_mnt
    [ ! -d $rootro_mnt ] && $MKDIR -p $rootro_mnt
    [ ! -b $loop_dev ]   && $MKNOD $loop_dev b 7 0

    if ! $MOUNT -o ro,loop,noatime,nodiratime $root_img $rootro_mnt ; then
        fatal "Failed to mount rootfs image."
    fi
    if ! $MOUNT -t tmpfs -o rw,noatime,mode=755 tmpfs $cow_mnt ; then
        fatal "Failed to mount tmpfs to back rootfs union."
    fi

    if ! $MOUNT -t aufs -o br:$cow_mnt=rw:$rootro_mnt=ro none $root_mnt ; then
        echo "failed to mount via aufs - trying unionfs..."
        if ! $MOUNT -t unionfs -o dirs=$cow_mnt=rw:$rootro_mnt=ro unionfs $root_mnt ; then
            fatal "Failed to mount union between $root_img and tmpfs at $cow_mnt."
        fi
    fi
}

measure_file() {
    local file=$1
    local pcr=$2
    local data=""

    [ -z $file ]   && fatal "no file provided to measure_file"
    [ ! -f $file ] && fatal "not a file: $file"
    [ -z $pcr ]    && fatal "no PCR provided to measure_file"
    if ! echo $pcr | grep -q '^[0-9]*$' ; then
        fatal "value for PCR provided to measure_file isn't a number: $pcr"
    fi

    # adding 'coreutils' to get sha1sum adds ~3MB to the initramfs
    #   wonder how long it takes the TPM to hash the whole rootfs?
    echo "measuring rootfs: $file"
    data=$(sha1sum -b $file | awk '{ print $1 }' | tr -d '\n')
    echo "extending PCR $pcr with value $data"
    echo -n "$data" | tpm_extendpcr --pcr $pcr
    [ $? -ne 0 ] && echo "tpm_extendpcr failed" && sleep 2
}

boot_root() {
    local rootmnt=$1

    [ -z $rootmnt ] && fatal "no root mount given to boot_root"
    /etc/init.d/trousers stop 2>/dev/null
    /etc/init.d/udev stop 2>/dev/null

    cd $rootmnt
    exec switch_root -c $CONSOLE $rootmnt /sbin/init
}

# XXX: bug workarounds
rm -rf /var/lock
mkdir -p /var/lock/lvm

# disable automount rules
rm -f /etc/udev/rules.d/automount.rules

early_setup
tss_setup
read_args

# do sed-tools magic

# populate /dev
mount -t devtmpfs devtmpfs $rootmnt/dev

# find me some mtab
ln -sf /proc/mounts /etc/mtab

sed_tools /dev/sda --boot-pba
