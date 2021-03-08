FROM alfresco/alfresco-base-java:11.0.10-openjdk-centos-8@sha256:343c8f63cf80c7af51785b93d6972b0c00087a1c0b995098cb8285c4d9db74b5

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

ENV ACTIVEMQ_HOME="/opt/activemq"
ENV ACTIVEMQ_BASE="/opt/activemq"
ENV ACTIVEMQ_CONF="/opt/activemq/conf"
ENV ACTIVEMQ_DATA="/opt/activemq/data"

ENV ACTIVEMQ_VERSION="5.16.1"
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
