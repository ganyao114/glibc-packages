#!/usr/bin/env bash

set -e

# adding configuration
. $(dirname "$(realpath "$0")")/init.sh

pkgname="$1"

chech_not_termux

if [ -z "$pkgname" ]; then
	error "no package name specified"
fi

if ! $(id ${GPKG_DEV_USER_NAME} &>/dev/null); then
	error "not found user ${GPKG_DEV_USER_NAME}"
fi

(
	if [ ! -d ${GPKG_DEV_DIR_SOURCE} ]; then
		error "not found source '${GPKG_DEV_DIR_SOURCE}'"
	fi
	cd ${GPKG_DEV_DIR_SOURCE}

	if [ ! -d $pkgname ]; then
		error "not found $pkgname"
	fi
	chmod a+rwx $pkgname
	cd $pkgname
	chmod a+rwx *

	# start building
	if [ ! -f src.tar.gz ]; then
		sudo -H -u ${GPKG_DEV_USER_NAME} bash -c "makepkg -o"
	else
		sudo -H -u ${GPKG_DEV_USER_NAME} bash -c "tar xf src.tar.gz"
	fi
	sudo -H -u ${GPKG_DEV_USER_NAME} bash -c '(timeout --preserve-status 300m makepkg -e --noarchive && ([ "$?" = "0" ] && makepkg -R)) || ([ "$?" = "143" ] && true)'

	if $(ls *.pkg.* &> /dev/null); then
		mv *.pkg.* ${GPKG_DEV_DIR_BUILD}
		echo " ${pkgname} " >> ${GPKG_DEV_DIR_BUILD}/gpkg-dev-done.txt
	else
		sudo -H -u ${GPKG_DEV_USER_NAME} bash -c "tar cf src.tar.gz src"
		mv src.tar.gz ${GPKG_DEV_DIR_BUILD}
		echo "${pkgname}" > ${GPKG_DEV_DIR_BUILD}/gpkg-dev-continue.txt
	fi
)
