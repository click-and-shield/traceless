# Docker Build Environment

This directory contains the Docker configuration used to build the Secure Debian ISO image.

## Build the Docker Image

```bash
docker build -t debian-trixie .
```

## Start the Build Container

Run the script [`start-container.sh`](start-container.sh):

```bash
dos2unix *.sh && chmod +x *.sh
./start-container.sh
```

The script performs the following actions:

* Creates the local directory `../live-build` (if it does not already exist).
* Creates the local directory `.apt-cache` (if it does not already exist).
* Starts a container based on the `debian-trixie` image.
  * Mounts the local `../live-build` directory as `/workspace` inside the container.
  * Mounts the local `.apt-cache` directory as `/var/cache/apt` to speed up package downloads and subsequent builds.

> See [Useful Docker Commands](../doc/docker.md) for additional information.
