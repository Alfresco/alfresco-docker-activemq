# Alfresco Anaxes Shipyard ActiveMQ Image
#
# Version 0.1

# This is an initial iteration and subject to change
FROM quay.io/alfresco/alfresco-base-java:8.0.202-oracle-centos-8-ebbcd20c6bf4@sha256:9d1e485d528dc0844073805ae21cba9f7bfb94b05c53d0227607aa230336979a

LABEL name="Alfresco ActiveMQ" \
    vendor="Alfresco" \
    license="Various" \
    build-date="unset"

# Set default user information
ARG GROUPNAME=Alfresco
ARG GROUPID=1000
ARG USERNAME=amq
ARG USERID=33031

ENV ACTIVEMQ_HOME="/opt/activemq"
ENV ACTIVEMQ_BASE="/opt/activemq"
ENV ACTIVEMQ_CONF="/opt/activemq/conf"
ENV ACTIVEMQ_DATA="/opt/activemq/data"

ENV ACTIVEMQ_VERSION="5.15.8"
ENV DOWNLOAD_URL="https://artifacts.alfresco.com/nexus/service/local/repositories/thirdparty/content/org/apache/apache-activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz"

RUN mkdir -p ${ACTIVEMQ_HOME} /data /var/log/activemq  && \
    curl ${DOWNLOAD_URL} -o /tmp/activemq.tar.gz && \
    tar -xzf /tmp/activemq.tar.gz -C /tmp && \
    mv /tmp/apache-activemq-${ACTIVEMQ_VERSION}/* ${ACTIVEMQ_HOME} && \
    rm -rf /tmp/activemq.tar.gz

RUN groupadd -g ${GROUPID} ${GROUPNAME} && \
    useradd -u ${USERID} -G ${GROUPNAME} ${USERNAME} && \
    chgrp -R ${GROUPNAME} ${ACTIVEMQ_HOME} && \
    chown -h ${USERNAME}:${GROUPNAME} $ACTIVEMQ_HOME && \
    chown ${USERNAME}:${GROUPNAME} ${ACTIVEMQ_DATA}/activemq.log && \
    chmod g+rwx ${ACTIVEMQ_DATA}

# Web Console
EXPOSE 8161
# OpenWire
EXPOSE 61616
# AMQP
EXPOSE 5672
# STOMP
EXPOSE 61613

VOLUME ["${ACTIVEMQ_DATA}"]
VOLUME ["/var/log/activemq"]
VOLUME ["${ACTIVEMQ_CONF}"]

WORKDIR ${ACTIVEMQ_HOME}
ADD init.sh ${ACTIVEMQ_HOME}
CMD ./init.sh ${ACTIVEMQ_HOME}

USER ${USERNAME}
CMD ${ACTIVEMQ_HOME}/bin/activemq console
