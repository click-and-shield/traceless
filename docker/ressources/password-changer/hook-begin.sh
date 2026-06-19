#!/bin/bash

install_password_changer() {

	create_local_binary_directory
	create_local_system_admin_bin_dir
	create_sudoers_directory

	cat >config/includes.chroot_after_packages/usr/local/sbin/password-changer.sh <<-'EOL'
	#!/bin/sh
	set -e

	if [ "$(id -u)" -ne 0 ]; then
	    echo "This script must be run as root." >&2
	    exit 1
	fi

	if [ -z "$1" ]; then
	    echo "Missing password." >&2
	    exit 1
	fi

	echo "user:$1" | chpasswd
	EOL

	chmod +x config/includes.chroot_after_packages/usr/local/sbin/password-changer.sh

	# Make the script that changes the password execute as root.
	cat >config/includes.chroot_after_packages/etc/sudoers.d/live-password-changer <<-'EOL'
		user ALL=(root) NOPASSWD: /usr/local/sbin/password-changer.sh
	EOL

	chmod 440 config/includes.chroot_after_packages/etc/sudoers.d/live-password-changer
}

install_password_changer
