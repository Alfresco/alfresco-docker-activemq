ARG JDIST
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR

FROM alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS activemq_image

ARG ACTIVEMQ_VERSION

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.name="Alfresco ActiveMQ" \
    org.label-schema.vendor="Alfresco" \
    org.label-schema.build-date="$CREATED" \
    org.opencontainers.image.title="Alfresco ActiveMQ" \
    org.opencontainers.image.vendor="Alfresco" \
    org.opencontainers.image.revision="$REVISION" \
    org.opencontainers.image.source="https://github.com/Alfresco/alfresco-docker-activemq" \
    org.opencontainers.image.created="$CREATED" \
    org.opencontainers.image.version="$ACTIVEMQ_VERSION"

# Set default user information
ARG GROUPNAME=Alfresco
ARG GROUPID=1000
ARG USERNAME=amq
ARG USERID=33031

ENV ACTIVEMQ_HOME="/opt/activemq"
ENV ACTIVEMQ_BASE="/opt/activemq"
ENV ACTIVEMQ_CONF="/opt/activemq/conf"
ENV ACTIVEMQ_DATA="/opt/activemq/data"
ENV ACTIVEMQ_BROKER_NAME="localhost"

ENV APACHE_MIRRORS="https://archive.apache.org/dist https://dlcdn.apache.org https://downloads.apache.org"
ENV DOWNLOAD_KEYS_URL="https://downloads.apache.org/activemq/KEYS"

ENV LC_ALL=C

# Install dependencies
RUN dnf install -y xmlstarlet gnupg curl && \
    dnf clean all

# Install ActiveMQ

RUN mkdir -p ${ACTIVEMQ_HOME} /data /var/log/activemq && \
    for base in ${APACHE_MIRRORS}; do \
      url="${base}/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz"; \
      echo "Trying $url"; \
      curl -fsSLo /tmp/activemq.tar.gz "$url" && break; \
    done && \
    for base in ${APACHE_MIRRORS}; do \
      url="${base}/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz.asc"; \
      curl -fsSLo /tmp/activemq.tar.gz.asc "$url" && break; \
    done && \
    curl -fsSLo /tmp/KEYS ${DOWNLOAD_KEYS_URL} && \
    gpg --batch --import /tmp/KEYS && \
    gpg --batch --verify /tmp/activemq.tar.gz.asc /tmp/activemq.tar.gz && \
    tar -xzf /tmp/activemq.tar.gz -C ${ACTIVEMQ_HOME} --strip-components=1 && \
    rm -rf /tmp/activemq.tar.gz /tmp/activemq.tar.gz.asc /tmp/KEYS /root/.gnupg

# Enable jaas authentication
RUN xmlstarlet ed -L \
    -N b="http://www.springframework.org/schema/beans" \
    -N x="http://activemq.apache.org/schema/core" \
    -s "/b:beans/x:broker[not(x:plugins)]" \
       -t elem -n plugins -v "" \
    -s "/b:beans/x:broker/plugins[not(jaasAuthenticationPlugin)]" \
       -t elem -n jaasAuthenticationPlugin -v "" \
    -i "/b:beans/x:broker/plugins/jaasAuthenticationPlugin[not(@configuration)]" \
       -t attr -n configuration -v "activemq" \
    ${ACTIVEMQ_HOME}/conf/activemq.xml

# Create runtime user
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

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR ${ACTIVEMQ_HOME}

USER ${USERNAME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["activemq", "console"]
