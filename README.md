# Alfresco ActiveMQ docker image

[![Build Status](https://img.shields.io/github/actions/workflow/status/Alfresco/alfresco-docker-activemq/build.yml?branch=master)](https://github.com/Alfresco/alfresco-docker-activemq/actions/workflows/build.yml)
![6.2-jre17-rockylinux8](https://img.shields.io/docker/v/alfresco/alfresco-activemq/6.2-jre17-rockylinux8)
![5.19-jre17-rockylinux8](https://img.shields.io/docker/v/alfresco/alfresco-activemq/5.19-jre17-rockylinux8)
![5.18-jre17-rockylinux8](https://img.shields.io/docker/v/alfresco/alfresco-activemq/5.18-jre17-rockylinux8)
![5.17-jre17-rockylinux8](https://img.shields.io/docker/v/alfresco/alfresco-activemq/5.17-jre17-rockylinux8)
![5.16-jre17-rockylinux8](https://img.shields.io/docker/v/alfresco/alfresco-activemq/5.16-jre17-rockylinux8)

This repository produces multi-arch ActiveMQ images compatible with all the
supported Alfresco versions that will be used by Alfresco engineering teams,
other internal groups in the organisation, customers and partners to run the
Alfresco Digital Business Platform.

## Quickstart

Multiple tags are available depending on the versions/flavours:

Activemq version | Java version | OS           | Image tag                | Size
-----------------|--------------|--------------|--------------------------|----------------
5.16             | 17           | Rockylinux 8 | `5.16-jre17-rockylinux8` | ![5.16 size][1]
5.17             | 17           | Rockylinux 8 | `5.17-jre17-rockylinux8` | ![5.17 size][2]
5.18             | 17           | Rockylinux 8 | `5.18-jre17-rockylinux8` | ![5.18 size][3]
5.19             | 17           | Rockylinux 8 | `5.19-jre17-rockylinux8` | ![5.19 size][4]
6.2              | 17           | Rockylinux 8 | `6.2-jre17-rockylinux8`  | ![6.2 size][5]

[1]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.16-jre17-rockylinux8
[2]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.17-jre17-rockylinux8
[3]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.18-jre17-rockylinux8
[4]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.19-jre17-rockylinux8
[5]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/6.2-jre17-rockylinux8

Additional tags available:

* `5.18.NN-jre17-rockylinux8` (full semver)

Built images are available on the following registries:

* [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-activemq) as `alfresco/alfresco-activemq`
* [Quay](https://quay.io/repository/alfresco/alfresco-activemq) as `quay.io/alfresco/alfresco-activemq` (requires authentication)

Example final image: `alfresco/alfresco-activemq:5.18-jre17-rockylinux8`

> If you are using this image in a public repository, please stick to the Docker Hub published image.

Images are built for `amd64` and `arm64` architectures.

### Image pinning

The [pinning suggestions provided in alfresco-base-java](https://github.com/Alfresco/alfresco-docker-base-java/blob/master/README.md#image-pinning) are valid for this image too.

## Configuration parameters

The following can be set via environment variables:

| Parameter               | Default value | Description                                          |
|:------------------------|:--------------|:-----------------------------------------------------|
| ACTIVEMQ_BROKER_NAME    | localhost     | The name of the broker of ActiveMQ server            |
| ACTIVEMQ_ADMIN_LOGIN    | admin         | The login for admin account (broker and web console) |
| ACTIVEMQ_ADMIN_PASSWORD | admin         | The password for admin account                       |
