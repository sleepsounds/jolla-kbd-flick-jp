#!/bin/sh
##############################################
#
# createrpm.sh
#
# This script create the langupack rpm.
#
##############################################

PKGNAME=jolla-kbd-flick-jp

if [ x"${TOPDIR}" == x ]; then
    TOPDIR=$HOME/rpmbuild
fi

if [ ! -d ${TOPDIR} ]; then
    rm -rf ${TOPDIR}
    mkdir ${TOPDIR}
fi

for n in SOURCES RPMS SRPMS BUILD BUILDROOT SPECS
do
    if [ ! -d ${TOPDIR}/$n ]; then
                mkdir ${TOPDIR}/$n
    fi  
done

SOURCEFILE=${TOPDIR}/SOURCES/${PKGNAME}.tar.gz

if [ ! -e ${SOURCEFILE} ]; then
    cd ..
    tar cvfz ${TOPDIR}/SOURCES/${PKGNAME}.tar.gz --exclude rpmbuild --exclude .git --exclude diff --exclude src/KeyboardBase_Flick.qml ./${PKGNAME}
    cd ${PKGNAME}
fi

rpmbuild -ba rpm/jolla-kbd-flick-jp.spec --target noarch

ls -l ${TOPDIR}/RPMS/noarch
ls -l ${TOPDIR}/SRPMS
