#!/usr/bin/env bash
set -e

# Allow remote access to web console (Jetty)
if [[ -f "${ACTIVEMQ_HOME}/conf/jetty.xml" ]]; then
  echo "Configuring Jetty to bind on 0.0.0.0"
  xmlstarlet ed -L \
  -N b="http://www.springframework.org/schema/beans" \
  -u "//b:bean[@id='jettyPort']/b:property[@name='host']/@value" \
  -v "0.0.0.0" \
  "${ACTIVEMQ_HOME}/conf/jetty.xml"
fi

# Overwrite users.properties with admin credentials
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    echo "${ACTIVEMQ_ADMIN_LOGIN}=${ACTIVEMQ_ADMIN_PASSWORD}" \
      > "${ACTIVEMQ_HOME}/conf/users.properties"
  else
    echo "admin=${ACTIVEMQ_ADMIN_PASSWORD}" \
      > "${ACTIVEMQ_HOME}/conf/users.properties"
  fi
fi

# Overwrite groups.properties to grant admin roles
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" && -f "${ACTIVEMQ_HOME}/conf/groups.properties" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    echo "admins=${ACTIVEMQ_ADMIN_LOGIN}" \
      > "${ACTIVEMQ_HOME}/conf/groups.properties"
  else
    echo "admins=admin" \
      > "${ACTIVEMQ_HOME}/conf/groups.properties"
  fi
fi

# Overwrite jetty-realm.properties for Jetty web console authentication
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" && -f "${ACTIVEMQ_HOME}/conf/jetty-realm.properties" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    echo "${ACTIVEMQ_ADMIN_LOGIN}: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      > "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  else
    echo "admin: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      > "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  fi
fi

# Overwrite credentials.properties for tooling / plugin authentication
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" && -f "${ACTIVEMQ_HOME}/conf/credentials.properties" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    USERNAME="${ACTIVEMQ_ADMIN_LOGIN}"
  else
    USERNAME="admin"
  fi

  cat > "${ACTIVEMQ_HOME}/conf/credentials.properties" <<EOF
activemq.username=${USERNAME}
activemq.password=${ACTIVEMQ_ADMIN_PASSWORD}
EOF
fi

# Set broker name placeholder in activemq.xml
xmlstarlet ed -L \
  -N b="http://www.springframework.org/schema/beans" \
  -N x="http://activemq.apache.org/schema/core" \
  -u "/b:beans/x:broker/@brokerName" \
  -v '${activemq.brokername}' \
  "${ACTIVEMQ_HOME}/conf/activemq.xml"

export ACTIVEMQ_OPTS="${ACTIVEMQ_OPTS:-} -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME}"

exec "${ACTIVEMQ_HOME}/bin/$@"
