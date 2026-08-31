# Building the ISO Image

To simplify the build process, the project includes a Docker environment containing all required dependencies.

## Build the Docker Image

```bash
docker build -t debian-trixie -f docker/Dockerfile docker
```

## Generate the ISO

1. Edit `docker/build.sh` according to your requirements:

   * **Optional**: configure keyboard layout. The default keyboard is `French AZERTY`. Please note that you can configure the keyboard easily once the OS has booted. Click [here](doc/images/config-kb.png) for details.
   * Add or remove packages.
   * Customize the system configuration.
   * Add scripts and configuration files.

2. Start the build container:

   ```bash
   dos2unix docker/*.sh && chmod +x docker/*.sh && docker/start-container.sh
   ```

3. Inside the container, run:

   ```bash
   bash /workspace/build.sh
   ```

If the build completes successfully, the generated ISO image will be available at:

```text
/workspace/secure_live/live-image-amd64.hybrid.iso
```

> The container directory `/workspace` is mapped to the host directory `live-build`.

> **Note**
>
> Avoid placing the _secure-debian directory tree_ in the directory `/tmp` on the host used to run the container.


