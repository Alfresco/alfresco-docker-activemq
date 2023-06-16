ARG JDIST
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR

#FROM alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} as ACTIVEMQ_IMAGE
FROM alfresco/alfresco-base-java:jre11-centos7 as ACTIVEMQ_IMAGE
LABEL org.label-schema.schema-version="1.0" \
	org.label-schema.name="Alfresco ActiveMQ" \
	org.label-schema.vendor="Alfresco" \
	org.label-schema.build-date="$CREATED" \
	org.opencontainers.image.title="Alfresco ActiveMQ" \
	org.opencontainers.image.vendor="Alfresco" \
	org.opencontainers.image.revision="$REVISION" \
	org.opencontainers.image.source="https://github.com/Alfresco/alfresco-docker-activemq" \
	org.opencontainers.image.created="$CREATED"

# Set default user information
ARG GROUPNAME=Alfresco
ARG GROUPID=1000
ARG USERNAME=amq
ARG USERID=33031
ARG ACTIVEMQ_VERSION=5.16.4

ENV ACTIVEMQ_HOME="/opt/activemq"
ENV ACTIVEMQ_BASE="/opt/activemq"
ENV ACTIVEMQ_CONF="/opt/activemq/conf"
ENV ACTIVEMQ_DATA="/opt/activemq/data"

ENV DOWNLOAD_URL="https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz"
ENV DOWNLOAD_ASC_URL="${DOWNLOAD_URL}.asc"
ENV DOWNLOAD_KEYS_URL="https://downloads.apache.org/activemq/KEYS"

ENV LC_ALL=C

RUN mkdir -p ${ACTIVEMQ_HOME} /data /var/log/activemq && \
    curl ${DOWNLOAD_URL} -so /tmp/activemq.tar.gz && \
    curl ${DOWNLOAD_ASC_URL} -so /tmp/activemq.tar.gz.asc && \
    curl ${DOWNLOAD_KEYS_URL} -so /tmp/KEYS && \
    gpg --import /tmp/KEYS && \
    gpg --verify /tmp/activemq.tar.gz.asc /tmp/activemq.tar.gz && \
    tar -xzf /tmp/activemq.tar.gz -C /tmp && \
    mv /tmp/apache-activemq-${ACTIVEMQ_VERSION}/* ${ACTIVEMQ_HOME} && \
    rm -rf /tmp/activemq.tar.gz /tmp/activemq.tar.gz.asc /tmp/KEYS

ADD init.sh ${ACTIVEMQ_HOME}

RUN groupadd -g ${GROUPID} ${GROUPNAME} && \
    useradd -u ${USERID} -G ${GROUPNAME} ${USERNAME} && \
    chgrp -R ${GROUPNAME} ${ACTIVEMQ_HOME} && \
    chown -h ${USERNAME}:${GROUPNAME} -R $ACTIVEMQ_HOME && \
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

USER ${USERNAME}
CMD ./init.sh ${ACTIVEMQ_HOME}
