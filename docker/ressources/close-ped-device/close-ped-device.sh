#!/bin/bash
set -euo pipefail

MAPPER_NAME="my-secret-storage"
MOUNT_DIR="/mnt/${MAPPER_NAME}"

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
# Close the device.
# =========================================================================

if mountpoint -q "${MOUNT_DIR}"; then
    sudo umount "${MOUNT_DIR}"
fi

if [ -e "/dev/mapper/${MAPPER_NAME}" ]; then
    sudo cryptsetup luksClose "${MAPPER_NAME}"
fi

zenity --info \
    --title="Volume closed" \
    --text="Encrypted volume has been unmounted and closed."
