#!/bin/bash

install_electrum() {
	# Copy the AppImage
	local -r ELECTRUM_URL="https://download.electrum.org/4.7.2/electrum-4.7.2-x86_64.AppImage"
	local -r APP_DIR="${ADDON_APPLICATION_SOFTWARE_PACKAGES_DIR}/electrum"
	local -r TARGET="${APP_DIR}/electrum.AppImage"
	local -r OFILE="/tmp/electrum.AppImage"

	# Download ELECTRUM only if necessary.
	if [ ! -f "${OFILE}" ]; then
		echo "downloading ELECTRUM"
		wget "${ELECTRUM_URL}" -O "${OFILE}"
	fi

	create_addon_application_software_packages_directory
	mkdir -p "${APP_DIR}"
	cp "${OFILE}" "${TARGET}"
	chmod +x "${TARGET}"
}

install_electrum
