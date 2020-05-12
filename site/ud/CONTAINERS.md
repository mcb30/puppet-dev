# Containers

You can specify container images to run via the `ud::containers`
[YAML](README.md#yaml) dictionary.  Each container will be run as a
`systemd` service using the `podman` container manager.

As an example, to specify that the host named `flowdemo` should run
the published [Node-RED container
image](https://nodered.org/docs/getting-started/docker) using Apache
as the front-end [web server](WEB.md), create the file
`data/nodes/flowdemo.yaml` containing:

```yaml
ud::web:
  app_port: 1880

ud::containers:
  nodered:
    image: docker.io/nodered/node-red
    ports:
      - 1880
```

Running non-trivial services from prebuilt container images is
invariably an exercise in pain, futility, and the tracking down of
information from an impressive variety of mutually contradictory
sources.  This misery is as nothing compared to the experience of
debugging a malfunctioning application distributed only as a prebuilt
container image.

As practice for this unpleasant experience, any further instructions
on using `ud::containers` must be reverse engineered from the rather
sparse documentation for the
[`ud::container`](REFERENCE.md#udcontainer) defined type.
