#!/bin/sh
set -e

CHOICE="$(zenity --list \
    --title="TraceLess Keyboard Settings" \
    --text="Select the keyboard layout to use:" \
    --column="Code" \
    --column="Keyboard layout" \
    fr "French AZERTY" \
    us "US QWERTY" \
    gb "UK QWERTY" \
    de "German QWERTZ" \
    es "Spanish" \
    it "Italian" \
    pt "Portuguese" \
    ro "Romanian" \
    --width=420 \
    --height=360)" || exit 0

sudo /usr/local/sbin/keyboard-configurator.sh "$CHOICE"

if command -v setxkbmap >/dev/null 2>&1; then
    setxkbmap "$CHOICE" || true
fi

zenity --info \
    --title="TraceLess Keyboard Settings" \
    --text="Keyboard layout changed to: $CHOICE"
