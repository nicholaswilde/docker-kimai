# Docker Kimai
[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/nicholaswilde/kimai)](https://hub.docker.com/r/nicholaswilde/kimai)
[![Docker Pulls](https://img.shields.io/docker/pulls/nicholaswilde/kimai)](https://hub.docker.com/r/nicholaswilde/kimai)
[![GitHub](https://img.shields.io/github/license/nicholaswilde/docker-kimai)](./LICENSE)
[![ci](https://github.com/nicholaswilde/docker-kimai/workflows/ci/badge.svg)](https://github.com/nicholaswilde/docker-kimai/actions?query=workflow%3Aci)
[![lint](https://github.com/nicholaswilde/docker-kimai/workflows/lint/badge.svg?branch=main)](https://github.com/nicholaswilde/docker-kimai/actions?query=workflow%3Alint)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

A multi-architecture image for [Kimai](https://www.kimai.cloud/).

## Requirements
- [buildx](https://docs.docker.com/engine/reference/commandline/buildx/)

## Usage

### docker-compose

Add the IP address of your server to the `TRUSTED_HOSTS` variable in the [docker-compose.yaml](./docker-compose.yaml) file.

Run the command and go to `https://<ip-address>:8001`
```bash
docker-compose up
```

## Build

Check that you can build the following:
```bash
$ docker buildx ls
NAME/NODE    DRIVER/ENDPOINT             STATUS  PLATFORMS
mybuilder *  docker-container
  mybuilder0 unix:///var/run/docker.sock running linux/amd64, linux/arm64, linux/arm/v7
```

If you are having trouble building arm images on a x86 machine, see [this blog post](https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/).

```
$ make build
```

## Pre-commit hook

If you want to automatically generate `README.md` files with a pre-commit hook, make sure you
[install the pre-commit binary](https://pre-commit.com/#install), and add a [.pre-commit-config.yaml file](./.pre-commit-config.yaml)
to your project. Then run:

```bash
pre-commit install
pre-commit install-hooks
```
Currently, this only works on `amd64` systems.

## License

[Apache 2.0 License](./LICENSE)

## Author
This project was started in 2020 by [Nicholas Wilde](https://github.com/nicholaswilde/).
