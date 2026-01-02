ARG JDIST
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR

FROM debian:12-slim AS activemq_build

ARG ACTIVEMQ_VERSION

ENV ACTIVEMQ_HOME=/opt/activemq
ENV APACHE_MIRRORS="https://archive.apache.org/dist https://dlcdn.apache.org https://downloads.apache.org"
ENV DOWNLOAD_KEYS_URL="https://downloads.apache.org/activemq/KEYS"
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      xmlstarlet && \
    rm -rf /var/lib/apt/lists/*

# Download + verify + unpack
RUN mkdir -p ${ACTIVEMQ_HOME} && \
    for m in ${APACHE_MIRRORS}; do \
      if curl -fsSLo /tmp/amq.tar.gz \
        ${m}/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz; then \
        curl -fsSLo /tmp/amq.tar.gz.asc \
          ${m}/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz.asc; \
        break; \
      fi; \
    done && \
    test -f /tmp/amq.tar.gz && \
    curl -fsSLo /tmp/KEYS ${DOWNLOAD_KEYS_URL} && \
    gpg --batch --import /tmp/KEYS && \
    gpg --batch --verify /tmp/amq.tar.gz.asc /tmp/amq.tar.gz && \
    tar -xzf /tmp/amq.tar.gz -C ${ACTIVEMQ_HOME} --strip-components=1 && \
    rm -rf /tmp/* /root/.gnupg

# Configure brokerName placeholder (build-time)
RUN xmlstarlet ed -L \
    -N b="http://www.springframework.org/schema/beans" \
    -N x="http://activemq.apache.org/schema/core" \
    -u "/b:beans/x:broker/@brokerName" \
    -v '${activemq.brokername}' \
    ${ACTIVEMQ_HOME}/conf/activemq.xml

# Bind Jetty to all interfaces (build-time)
RUN if [ -f "${ACTIVEMQ_HOME}/conf/jetty.xml" ]; then \
      xmlstarlet ed -L \
        -N b="http://www.springframework.org/schema/beans" \
        -u "//b:bean[@id='jettyPort']/b:property[@name='host']/@value" \
        -v "0.0.0.0" \
        "${ACTIVEMQ_HOME}/conf/jetty.xml"; \
    fi

FROM alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} as activemq_image

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

ARG GROUPNAME=Alfresco
ARG GROUPID=1000
ARG USERNAME=amq
ARG USERID=33031

ENV ACTIVEMQ_HOME=/opt/activemq
ENV ACTIVEMQ_BASE=/opt/activemq
ENV ACTIVEMQ_CONF=/opt/activemq/conf
ENV ACTIVEMQ_DATA=/opt/activemq/data
ENV ACTIVEMQ_BROKER_NAME=localhost
ENV LC_ALL=C

# Create runtime user
RUN groupadd -g ${GROUPID} ${GROUPNAME} && \
    useradd -u ${USERID} -g ${GROUPNAME} ${USERNAME}

# Copy prepared distribution
COPY --from=activemq_build /opt/activemq ${ACTIVEMQ_HOME}

# Runtime directories + permissions
RUN mkdir -p ${ACTIVEMQ_DATA} /var/log/activemq && \
    chown -R ${USERNAME}:${GROUPNAME} \
      ${ACTIVEMQ_HOME} \
      ${ACTIVEMQ_DATA} \
      /var/log/activemq

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR ${ACTIVEMQ_HOME}
USER ${USERNAME}

EXPOSE 8161 61616 5672 61613

VOLUME ["${ACTIVEMQ_DATA}", "/var/log/activemq", "${ACTIVEMQ_CONF}"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["activemq", "console"]
