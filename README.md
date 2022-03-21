# Welcome to Alfresco ActiveMQ docker image

## Introduction

This repository contains the Dockerfile used to create the Alfresco ActiveMQ image that
will be used by Alfresco engineering teams, other internal groups in the
organisation, customers and partners to run the Alfresco Digital Business Platform.

## Configuration parameters:
The following can be set via environment variables:

| Parameter               | Default value | Description                                          |
|:------------------------|:--------------|:-----------------------------------------------------|
| ACTIVEMQ_BROKER_NAME    | localhost     | The name of the broker of ActiveMQ server            |
| ACTIVEMQ_ADMIN_LOGIN    | admin         | The login for admin account (broker and web console) |
| ACTIVEMQ_ADMIN_PASSWORD | admin         | The password for admin account                       |
