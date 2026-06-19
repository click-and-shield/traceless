#!/bin/bash

install_keyboard_configurator() {

	create_local_binary_directory
	create_sudoers_directory
	create_local_system_admin_bin_dir

	cat >config/includes.chroot_after_packages/usr/local/sbin/keyboard-configurator.sh <<-'EOL'
	#!/bin/sh
	set -e

	LAYOUT="$1"
	VARIANT="${2:-}"

	case "$LAYOUT" in
	    fr|us|gb|de|es|it|pt|ro)
	        ;;
	    *)
	        echo "Unsupported keyboard layout: $LAYOUT" >&2
	        exit 1
	        ;;
	esac

	cat >/etc/default/keyboard <<EOF
	XKBMODEL="pc105"
	XKBLAYOUT="$LAYOUT"
	XKBVARIANT="$VARIANT"
	XKBOPTIONS=""

	BACKSPACE="guess"
	EOF

	setupcon || true
	udevadm trigger --subsystem-match=input --action=change || true
	EOL

	chmod +x config/includes.chroot_after_packages/usr/local/sbin/keyboard-configurator.sh

	# Make the script that changes the keyboard configuration execute as root.
	cat >config/includes.chroot_after_packages/etc/sudoers.d/live-keyboard-configurator <<-'EOL'
	user ALL=(root) NOPASSWD: /usr/local/sbin/keyboard-configurator.sh
	EOL

	chmod 440 config/includes.chroot_after_packages/etc/sudoers.d/live-keyboard-configurator
}

install_keyboard_configurator
