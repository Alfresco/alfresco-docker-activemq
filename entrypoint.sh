#!/usr/bin/env bash
set -e

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

export ACTIVEMQ_OPTS="${ACTIVEMQ_OPTS:-} -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME}"

exec "${ACTIVEMQ_HOME}/bin/$@"
