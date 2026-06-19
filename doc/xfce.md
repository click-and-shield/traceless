# XFCE commands

## Mark a XFCE desktop launcher as "executable"

```bash
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
TARGET="${DESKTOP_DIR}/electrum.desktop"
gio info "${TARGET}"
gio info "${TARGET}" | grep -i "metadata::xfce-exe-checksum"
gio set -t string "${TARGET}" metadata::xfce-exe-checksum "$(sha256sum "${TARGET}" | awk '{print $1}')"
```

If you need to remove the property "`metadata::xfce-exe-checksum`" for testing purposes:

```bash
gio set --type=unset "${TARGET}" "metadata::xfce-exe-checksum"
gio info "${TARGET}" | grep -i "metadata::xfce-exe-checksum"
```


