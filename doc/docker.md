# Useful Docker commands

List all containers:

```bash
docker container ls --all
docker container ls --all --format  "{{.ID}}"
```

Delete a container:

```bash
docker rm <container ID>
```

Get the ID of a running container, identified by its name $NAME:

```bash
NAME=brave_haibt
docker ps --filter="name=${NAME}" --filter="status=running" --format="{{.ID}}"
```

Stop a container:

```bash
docker stop <container ID>
```
