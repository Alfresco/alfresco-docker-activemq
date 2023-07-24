# Alfresco ActiveMQ docker image

[![Build Status](https://img.shields.io/github/actions/workflow/status/Alfresco/alfresco-docker-activemq/build.yml?branch=master)](https://github.com/Alfresco/alfresco-docker-activemq/actions/workflows/build.yml)

This repository contains the Dockerfile used to create the Alfresco ActiveMQ
image that will be used by Alfresco engineering teams, other internal groups in
the organisation, customers and partners to run the Alfresco Digital Business
Platform.

## Quickstart

Choose between one of the available flavours built from this repository:

Activemq version | Java version | OS           | Image tag                | Size
-----------------|--------------|--------------|--------------------------|----------------
5.16             | 17           | Rockylinux 8 | 5.16-jre17-rockylinux8 | ![5.16 size][1]
5.17             | 17           | Rockylinux 8 | 5.17-jre17-rockylinux8 | ![5.17 size][2]
5.18             | 17           | Rockylinux 8 | 5.18-jre17-rockylinux8 | ![5.18 size][3]

[1]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.16-jre17-rockylinux8
[2]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.17-jre17-rockylinux8
[3]: https://img.shields.io/docker/image-size/alfresco/alfresco-activemq/5.18-jre17-rockylinux8

* [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-activemq) image name: `alfresco/alfresco-activemq`
* [Quay](https://quay.io/repository/alfresco/alfresco-activemq) image name: `quay.io/alfresco/alfresco-activemq`

Example final image: `alfresco/alfresco-activemq:5.18-jre17-rockylinux8`

> If you are using this base image in a public repository, please stick to the Docker Hub published image.

## Configuration parameters

The following can be set via environment variables:

| Parameter               | Default value | Description                                          |
|:------------------------|:--------------|:-----------------------------------------------------|
| ACTIVEMQ_BROKER_NAME    | localhost     | The name of the broker of ActiveMQ server            |
| ACTIVEMQ_ADMIN_LOGIN    | admin         | The login for admin account (broker and web console) |
| ACTIVEMQ_ADMIN_PASSWORD | admin         | The password for admin account                       |
