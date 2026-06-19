#!/bin/sh

PASSWORD1="$(zenity --password --title="Change user password")" || exit 1
PASSWORD2="$(zenity --password --title="Confirm new password")" || exit 1

if [ "${PASSWORD1}" != "${PASSWORD2}" ]; then
    zenity --error --text="Passwords do not match."
    exit 1
fi

if [ -z "${PASSWORD1}" ]; then
    zenity --error --text="Password cannot be empty."
    exit 1
fi

sudo /usr/local/sbin/password-changer.sh "${PASSWORD1}"

zenity --info --text="Password changed successfully."
