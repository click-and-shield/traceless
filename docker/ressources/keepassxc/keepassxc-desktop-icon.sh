#!/bin/sh
set -e

# Note: the file "/usr/share/applications/luckyluks.desktop" already exists.
#       It is installed with the software package.
FILE="keepassxc.desktop"
MARKER_FILE="${HOME}/.${FILE}.created"

if [ -f "${MARKER_FILE}" ]; then
	exit 0
fi

DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
if [ -z "${DESKTOP_DIR}" ] || [ "${DESKTOP_DIR}" = "${HOME}" ]; then
	DESKTOP_DIR="${HOME}/Desktop"
fi
mkdir -p "${DESKTOP_DIR}"

TARGET="${DESKTOP_DIR}/${FILE}"
cp -n "/usr/share/applications/org.keepassxc.KeePassXC.desktop" "${TARGET}"
chmod +x "${TARGET}"
gio set -t string "${TARGET}" metadata::xfce-exe-checksum "$(sha256sum "${TARGET}" | awk '{print $1}')"

touch "${MARKER_FILE}"
