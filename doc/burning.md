# Creating a USB bootable key

## Using a GUI

We recommend using [Etcher](https://etcher.balena.io/).

This software is available for Windows, Mac and Linux.

## From a Linux command line

Assuming that the ID of the mounted USB key is `/dev/sdb`:

```
sudo umount /dev/sdb*
sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdb bs=4M status=progress oflag=sync
sudo sync
sudo eject /dev/sdb
```

