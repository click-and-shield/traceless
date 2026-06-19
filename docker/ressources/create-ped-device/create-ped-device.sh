#!/bin/bash
#
# Prepare a deniable encrypted USB device using LUKS with a detached header.
#
# WARNING:
# - The selected USB device will be completely overwritten.
# - The detached LUKS header is mandatory to reopen the encrypted device.
# - If the header is lost, the encrypted data becomes unrecoverable.

set -euo pipefail

TIMESTAMP=$(date -u +%s)
HEADER_FILE="/dev/shm/luksheader-${TIMESTAMP}.img"
MAPPER_NAME="my-secret-storage"
MAPPED_DEVICE="/dev/mapper/${MAPPER_NAME}"

# =========================================================================
# Select the target USB device.
# =========================================================================

declare -a zenity_items=()
declare -A device_by_label=()

mapfile -t names < <(lsblk -dn -o NAME | grep -vE '^loop')

for name in "${names[@]}"
do
    label="$(lsblk -dn -o LABEL "/dev/${name}" || true)"
    type="$(lsblk -dn -o TYPE  "/dev/${name}" || true)"
    tran="$(lsblk -dn -o TRAN  "/dev/${name}" || true)"

    [ "${type}" = "disk" ] || continue
    [ "${tran}" = "usb" ] || continue

    if [ -z "${label}" ]; then
        item="${name}: <no label>"
    else
        item="${name}: ${label}"
    fi

    zenity_items+=("${item}")
    device_by_label["${item}"]="${name}"
done

if [ "${#zenity_items[@]}" -eq 0 ]; then
    zenity --error --text="No USB storage device found."
    exit 1
fi

selected_item="$(
    zenity --list \
        --title="Select USB device" \
        --text="Select the USB device to erase and encrypt:" \
        --column="Device" \
        "${zenity_items[@]}"
)" || exit 1

selected_device="${device_by_label[${selected_item}]}"
DEVICE="/dev/${selected_device}"

# =========================================================================
# Confirm the destructive operation.
# =========================================================================

zenity --question \
    --title="Confirm destructive operation" \
    --text="All data on ${DEVICE} will be permanently destroyed.\n\nDo you want to continue?" \
    || exit 1

# =========================================================================
# Ask for the LUKS passphrase.
# =========================================================================

K1="$(zenity --password --title="Enter the secret key")" || exit 1
K2="$(zenity --password --title="Confirm the secret key")" || exit 1

if [ "${K1}" != "${K2}" ]; then
    zenity --error --text="Secret keys do not match."
    exit 1
fi

if [ -z "${K1}" ]; then
    zenity --error --text="Secret key cannot be empty."
    exit 1
fi

# =========================================================================
# Unmount all mounted partitions belonging to the selected device.
# =========================================================================

while read -r mountpoint
do
    [ -n "${mountpoint}" ] || continue
    sudo umount --verbose "${mountpoint}"
done < <(lsblk -nr -o MOUNTPOINTS "${DEVICE}" | grep -v '^$' || true)

# =========================================================================
# Overwrite the USB device with random data.
# =========================================================================

zenity --info \
    --title="Randomization" \
    --text="The device will now be overwritten with random data.\nThis may take a long time."

SIZE="$(lsblk -dn -b -o SIZE "${DEVICE}")"


echo "Overwrite the USB device \"${DEVICE}\" with random data."
echo "Size of device: ${SIZE} bytes"

set +e

sudo dd \
    if=/dev/urandom \
    of="${DEVICE}" \
    bs=16M \
    status=progress \
    conv=fsync

RC=$?

set -e

if [ "${RC}" -ne 0 ]; then
    echo "End of device reached (expected)."
fi

# =========================================================================
# Create a detached LUKS header.
# =========================================================================

if [ -f "${HEADER_FILE}" ]; then
    rm -f "${HEADER_FILE}"
fi
umask 077 # Set the user’s file creation mask.

echo "Create a detached LUKS header \"${HEADER_FILE}\"."
printf '%s' "${K1}" | sudo cryptsetup luksFormat \
    --type luks2 \
    --batch-mode \
    --key-file - \
    --header "${HEADER_FILE}" \
    "${DEVICE}"

# =========================================================================
# Create a filesystem inside the encrypted volume.
# =========================================================================

# 1. Open the encrypted device using the detached LUKS header.
echo "Open the encrypted device \"${DEVICE}\" using the detached LUKS header \"${HEADER_FILE}\"."
printf '%s' "${K1}" | sudo cryptsetup luksOpen \
    --key-file - \
    --header "${HEADER_FILE}" \
    "${DEVICE}" \
    "${MAPPER_NAME}"

# 2. Create the filesystem inside the decrypted mapper device.
echo "Create the filesystem inside the decrypted mapper device \"${HEADER_FILE}\"."
sudo mkfs.ext4 -F "${MAPPED_DEVICE}"

# 3. Close the encrypted volume.
echo "Close the encrypted volume \"${HEADER_FILE}\"."
sudo cryptsetup luksClose "${MAPPER_NAME}"

unset K1
unset K2

ls -lah "${HEADER_FILE}"

zenity --warning \
    --title="Detached LUKS header created" \
    --text="The detached LUKS header has been created here:\n\n${HEADER_FILE}\n\nYou MUST copy this file to a persistent and secure location.\n\nWithout this header, the encrypted USB device cannot be opened."


    