#!/bin/bash

# Turn on "strict mode".
# - See http://redsymbol.net/articles/unofficial-bash-strict-mode/.
# - See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#The-Set-Builtin
#
# -e: exit immediately if a pipeline, which may consist of a single simple command, a list,
#     or a compound command returns a non-zero status. 
# -u: treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as
#     an error when performing parameter expansion. An error message will be written to the
#     standard error, and a non-interactive shell will exit.
# -o pipefail: if set, the return value of a pipeline is the value of the last (rightmost)
#              command to exit with a non-zero status, or zero if all commands in the pipeline
#              exit successfully.
set -eu -o pipefail

__FILE_NAME__="${BASH_SOURCE[0]}"
while [ -h "${__FILE_NAME__}" ] ; do __FILE_NAME__="$(readlink "${__FILE_NAME__}")"; done
__DIR__="$( cd -P "$( dirname "${__FILE_NAME__}" )" && pwd )"
declare -r __DIR__

TARGET_DIR="${__DIR__}/secure_live"
declare -r TARGET_DIR
WORKSPACE="/workspace"
declare -r WORKSPACE

mkdir -p "${TARGET_DIR}"

cd "${TARGET_DIR}"

lb clean --purge 2>/dev/null || true

lb config \
	--mode debian \
	--distribution bookworm \
	--binary-images iso-hybrid \
	--debian-installer live \
	--archive-areas "main contrib non-free non-free-firmware" \
	--bootappend-live "boot=live components toram username=user hostname=securelive" || exit 1

mkdir -p \
	config/package-lists \
	config/hooks/live \
	config/includes.chroot_after_packages/etc/systemd/system \
	config/includes.chroot_after_packages/etc/systemd/journald.conf.d \
	config/includes.chroot_after_packages/etc/lightdm/lightdm.conf.d \
	config/includes.chroot_after_packages/etc/default \
	config/includes.chroot_after_packages/usr/local/bin

# SYSTEM_PIXMAP_DIR: local directory where icons are stored.

readonly LOCAL_BIN_DIR="config/includes.chroot_after_packages/usr/local/bin"
readonly SYSTEM_WIDE_APPLICATION_DIR="config/includes.chroot_after_packages/usr/share/applications"
readonly SYSTEM_WIDE_AUTOSTART_DIR="config/includes.chroot_after_packages/etc/xdg/autostart"
readonly SYSTEM_PIXMAP_DIR="config/includes.chroot_after_packages/usr/share/pixmaps"
readonly ADDON_APPLICATION_SOFTWARE_PACKAGES_DIR="config/includes.chroot_after_packages/opt"
readonly LOCAL_SYSTEM_ADMIN_BIN_DIR="config/includes.chroot_after_packages/usr/local/sbin"
readonly SUDOERS_INCLUDE_DIR="config/includes.chroot_after_packages/etc/sudoers.d"


create_local_binary_directory() {
	mkdir -p "${LOCAL_BIN_DIR}"
}

create_system_wide_applications_directory() {
	mkdir -p "${SYSTEM_WIDE_APPLICATION_DIR}"
}

create_system_wide_autostart_directory() {
	mkdir -p "${SYSTEM_WIDE_AUTOSTART_DIR}"
}

create_system_pixmap_directory() {
	mkdir -p "${SYSTEM_PIXMAP_DIR}"
}

create_addon_application_software_packages_directory() {
	mkdir -p "${ADDON_APPLICATION_SOFTWARE_PACKAGES_DIR}"
}

create_local_system_admin_bin_dir() {
	mkdir -p "${LOCAL_SYSTEM_ADMIN_BIN_DIR}"
}

create_sudoers_directory() {
	mkdir -p "${SUDOERS_INCLUDE_DIR}"
}


configure_xfce_keyboard() {
	echo "Configure xfce keyboard"
	cat >config/includes.chroot_after_packages/etc/default/keyboard <<-EOL
	XKBMODEL="pc105"
	XKBLAYOUT="fr"
	XKBVARIANT=""
	XKBOPTIONS=""
	BACKSPACE="guess"
	EOL
}

configure_console_keyboard() {
	echo "Configure Console keyboard"

	cat >config/includes.chroot_after_packages/etc/default/console-setup <<-EOL
	ACTIVE_CONSOLES="/dev/tty[1-6]"
	CHARMAP="UTF-8"
	CODESET="Lat15"
	FONTFACE="Fixed"
	FONTSIZE="8x16"
	EOL

	cat > config/includes.chroot_after_packages/etc/locale.gen <<-EOL
	fr_FR.UTF-8 UTF-8
	en_US.UTF-8 UTF-8
	EOL

	cat >config/hooks/live/20-locale-keyboard.chroot <<-EOL
	#!/bin/bash
	set -e
	locale-gen
	update-locale LANG=fr_FR.UTF-8
	dpkg-reconfigure -f noninteractive keyboard-configuration
	setupcon || true
	EOL

	chmod +x config/hooks/live/20-locale-keyboard.chroot
}

configure_auto_xfce_login() {
	# Ref: https://wiki.debian.org/fr/LightDM
	echo "Configure xfce auto login"
	cat >config/includes.chroot_after_packages/etc/lightdm/lightdm.conf.d/50-autologin.conf <<-EOL
	[Seat:*]
	autologin-user=user
	autologin-user-timeout=0
	EOL
}

configure_packages() {
	echo "Configure the list of packages to install"

	add_protonvpn() {
		cat >config/hooks/live/50-install-protonvpn.chroot <<-EOL
		#!/bin/bash
		set -e
		wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb
		dpkg -i protonvpn-stable-release_1.0.8_all.deb
		apt update
		apt install -y proton-vpn-cli
		EOL

		chmod +x config/hooks/live/50-install-protonvpn.chroot
	}



	cat >config/package-lists/custom.list.chroot <<-EOL
	# Network
	openvpn
	network-manager
	network-manager-gnome
	openssl
	openssh-client
	# Security
	keepassxc
	cryptsetup
	gnupg
	age
	luckyluks
	# Utilities
	dos2unix
	vim
	curl
	wget
	rsync
	firefox-esr
	htop
	btop
	libreoffice-writer
	zenity
	sudo
	# GUI interface
	xfce4
	lightdm
	libglib2.0-bin
	xfce4-terminal
	# Keyboeard configuration
	keyboard-configuration
	console-setup
	locales
	x11-xserver-utils
	# Install Electrum
	fuse3
	libfuse2
	libgl1
	libegl1
	libxkbcommon-x11-0
	libxcb-cursor0
	libxcb-xinerama0
	libxcb-icccm4
	libxcb-image0
	libxcb-keysyms1
	libxcb-render-util0
	libdbus-1-3
	libfontconfig1
	EOL

	add_protonvpn
}

configure_swap() {
	echo "Configure he SWAP"

	cat >config/includes.chroot_after_packages/etc/systemd/system/disable-swap.service <<-EOL
	[Unit]
	Description=Disable swap
	After=multi-user.target

	[Service]
	Type=oneshot
	ExecStart=/sbin/swapoff -a

	[Install]
	WantedBy=multi-user.target
	EOL

	cat >config/hooks/live/02-enable-disable-swap.chroot <<-EOL
	#!/bin/bash
	set -e
	systemctl enable disable-swap.service
	EOL

	chmod +x config/hooks/live/02-enable-disable-swap.chroot
}

configure_volatile_logs() {
	echo "Configure the LOGs"

	cat >config/includes.chroot_after_packages/etc/systemd/journald.conf.d/volatile.conf <<-EOL
	[Journal]
	Storage=volatile
	RuntimeMaxUse=100M
	EOL
}

configure_tmp() {
	echo "Configure the temporary directory"

	cat >config/includes.chroot_after_packages/etc/fstab <<-EOL
	tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
	tmpfs /var/tmp tmpfs defaults,noatime,mode=1777 0 0
	EOL
}

update_os() {
	echo "Update the OS"

	cat >config/hooks/live/11-apt-update.chroot <<-EOL
	#!/bin/bash
	set -e
	apt update
	EOL

	chmod +x config/hooks/live/11-apt-update.chroot
}

add_custom_scripts() {
	echo "Add custom scripts"

	cat >config/includes.chroot_after_packages/usr/local/bin/custom-script.sh <<-EOL
	#!/bin/bash
	echo "This is a custom script"
	EOL

	chmod +x config/includes.chroot_after_packages/usr/local/bin/custom-script.sh	
}

configure_user_password() {
	echo "Configure user password"

	cat >config/includes.chroot_after_packages/etc/systemd/system/set-default-user-password.service <<-'EOL'
	[Unit]
	Description=Set default password for live user
	After=multi-user.target

	[Service]
	Type=oneshot
	ExecStart=/bin/sh -c 'id user >/dev/null 2>&1 && echo "user:live" | chpasswd'

	[Install]
	WantedBy=multi-user.target
	EOL

	cat >config/hooks/live/03-enable-default-password.chroot <<-'EOL'
	#!/bin/bash
	set -e
	systemctl enable set-default-user-password.service
	EOL

	chmod +x config/hooks/live/03-enable-default-password.chroot
}

# Setup a desktop icon for an optionally pre-installed application.
#
# - If the application is already installed, then the function only adds a desktop
#   icon for the application.
# - Otherwise, the function installs the application and then sets up a desktop icon 
#   for the application.
#
# <app name>
#      - Mandatory:
#        - <app name>-desktop-icon.desktop
#          Tells XFCE to execute a script each time the user logs in.
#          This executed script is "<app name>-desktop-icon.sh" (see below).
#        - <app name>-desktop-icon.sh
#          The script executed (by XFCE) each time the user logs in.
#      - Optional:
#        - <app name>.desktop 
#          Tells XFCE to add an entry for the application in the application explorer.
#          May already be created for applications installed using the OS package manager.
#        - <app name>.svg
#          The icon to be shown on the desktop for the application.
#          May already be created for applications installed using the OS package manager.
#        - <app name>.sh
#          An optional intermediate launcher.
#          May not be necessary for applications installed using the OS package manager.
#        - hook-begin.sh
#          Script used to execute special actions before the process begins.
#          Only required if the configuration needs nonstandard actions.
# @param #1 the name of the application.
#           Ex: "create_ped-device"
# @return None

install_app() {
	local -r APP_NAME="${1}"
	local -r LOCAL_SRC="${WORKSPACE}/${APP_NAME}"
	local -r LAUNCHER="${APP_NAME}.sh"
	local -r DESKTOP_ENTRY="${APP_NAME}.desktop"
	local -r DESKTOP_ICON_CONFIG="${APP_NAME}-desktop-icon.desktop"
	local -r DESKTOP_ICON_CREATOR="${APP_NAME}-desktop-icon.sh"
	local -r ICON="${APP_NAME}.svg"
	local -r HOOK_BEGIN="${LOCAL_SRC}/hook-begin.sh"

	local TARGET=""

	# Check that all resources are available.

	if [ ! -d "${LOCAL_SRC}" ]; then
		echo "The container directory \"${LOCAL_SRC}\" does not exist!"
		exit 1
	fi

	if [ ! -f "${LOCAL_SRC}/${DESKTOP_ICON_CONFIG}" ]; then
		echo "The configuration file \"${LOCAL_SRC}/${DESKTOP_ICON_CREATOR}\" does not exist!"
		exit 1
	fi

	if [ ! -f "${LOCAL_SRC}/${DESKTOP_ICON_CREATOR}" ]; then
		echo "The script file \"${LOCAL_SRC}/${DESKTOP_ICON_CREATOR}\" does not exist!"
		exit 1
	fi

	# May not be necessary for applications installed using the OS package manager.
	if [ ! -f "${LOCAL_SRC}/${LAUNCHER}" ]; then
		echo "WARNING: The script \"${LOCAL_SRC}/${APP_NAME}.sh\" does not exist!"
	fi

	# May already be created for applications installed using the OS package manager.
	if [ ! -f "${LOCAL_SRC}/${DESKTOP_ENTRY}" ]; then
		echo "WARNING: The desktop configuration file \"${LOCAL_SRC}/${DESKTOP_ENTRY}\" does not exist!"
	fi

	# May already be created for applications installed using the OS package manager.
	if [ ! -f "${LOCAL_SRC}/${ICON}" ]; then
		echo "WARNING: The icon file \"${LOCAL_SRC}/${ICON}\" does not exist!"
	fi

	# Execute the hook designed to be executed at the beginning of the installation process.
	# Only required if the configuration needs nonstandard actions.
	if [ -f "${HOOK_BEGIN}" ]; then
		. "${HOOK_BEGIN}"
	fi

	# Create the executable (<app name>.sh).
	if [ -f "${LOCAL_SRC}/${LAUNCHER}" ]; then
		create_local_binary_directory
		TARGET="${LOCAL_BIN_DIR}/${LAUNCHER}"
		cp "${LOCAL_SRC}/${LAUNCHER}" "${TARGET}"
		chmod +x "${TARGET}"
	fi

	# Declare the entry in the application selector (create-ped-device.desktop).
	# - Declaration:       <app name>.desktop
	# - Script to execute: <app name>.sh
	if [ -f "${LOCAL_SRC}/${DESKTOP_ENTRY}" ]; then
		create_system_wide_applications_directory
		cp "${LOCAL_SRC}/${DESKTOP_ENTRY}" "${SYSTEM_WIDE_APPLICATION_DIR}/${DESKTOP_ENTRY}"
	fi

	# Declare the script (.sh) used to create the desktop icon.
	# - Delaration:        <app name>-desktop-icon.desktop
	# - Script to execute: <app name>-desktop-icon.sh (see the next section)
	create_system_wide_autostart_directory
	cp "${LOCAL_SRC}/${DESKTOP_ICON_CONFIG}" "${SYSTEM_WIDE_AUTOSTART_DIR}/${DESKTOP_ICON_CONFIG}"

	# Create the script used to create the desktop icon (<app name>-desktop-icon.sh).
	create_local_binary_directory
	TARGET="${LOCAL_BIN_DIR}/${DESKTOP_ICON_CREATOR}"
	cp "${LOCAL_SRC}/${DESKTOP_ICON_CREATOR}" "${TARGET}"
	chmod +x "${TARGET}"

	# Copy the icon (<app name>.svg).
	# May already be created for applications installed using the OS package manager.
	if [ -f "${LOCAL_SRC}/${ICON}" ]; then
		create_system_pixmap_directory
		cp "${LOCAL_SRC}/${ICON}" "${SYSTEM_PIXMAP_DIR}/${ICON}"
	fi
}


main() {
	configure_xfce_keyboard
	configure_console_keyboard
	configure_auto_xfce_login
	configure_packages
	configure_swap
	configure_volatile_logs
	configure_tmp
	add_custom_scripts
	configure_user_password
	install_app "create-ped-device"
	install_app "open-ped-device"
	install_app "close-ped-device"
	install_app "electrum"
	install_app "password-changer"
	install_app "keyboard-configurator"
	install_app "luckyluks"
	install_app "keepassxc"
	update_os
	lb build
}

main

