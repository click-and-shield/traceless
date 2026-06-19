# Boot configuration

```bash
mkdir /tmp/iso
mount -o loop live-image-amd64.hybrid.iso /tmp/iso
cd iso
find /tmp/iso -type f | grep -E 'grub|isolinux|syslinux'
find /tmp/iso -name '*.cfg'
cat /tmp/iso/boot/grub/grub.cfg
cat /tmp/iso/boot/grub/config.cfg
```


