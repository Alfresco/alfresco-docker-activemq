#!/usr/bin/env bash
set -e

# ------------------------------------------------
# 1. Allow remote access to web console (Jetty)
# ------------------------------------------------
if [[ -f "${ACTIVEMQ_HOME}/conf/jetty.xml" ]]; then
  sed -i 's/127.0.0.1/0.0.0.0/g' "${ACTIVEMQ_HOME}/conf/jetty.xml"
fi
xmlstarlet ed -L \
  -u "//Set[@name='host']" \
  -v "0.0.0.0" \
  "${ACTIVEMQ_HOME}/conf/jetty.xml"
# ------------------------------------------------
# 2. Configure admin user via JAAS (users.properties)
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" ]]; then
    ADMIN_USER="${ACTIVEMQ_ADMIN_LOGIN}"
  else
    ADMIN_USER="admin"
  fi

  echo "Configuring JAAS users.properties (overwrite mode)"
  echo "${ADMIN_USER}=${ACTIVEMQ_ADMIN_PASSWORD}" \
    > "${CONF_DIR}/users.properties"
fi

# ------------------------------------------------
# 2b. Grant admin role (groups.properties) – REQUIRED for 6.x
# ------------------------------------------------
if [[ -f "${CONF_DIR}/groups.properties" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" ]]; then
    ADMIN_USER="${ACTIVEMQ_ADMIN_LOGIN}"
  else
    ADMIN_USER="admin"
  fi

  echo "Configuring groups.properties (overwrite mode)"
  echo "admins=${ADMIN_USER}" \
    > "${CONF_DIR}/groups.properties"
fi


# ------------------------------------------------
# 3. ActiveMQ 5.x – configure jetty-realm.properties
# ------------------------------------------------
if [[ -f "${CONF_DIR}/jetty-realm.properties" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  echo "ActiveMQ 5.x detected – configuring jetty-realm.properties (overwrite mode)"

  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" ]]; then
    echo "${ACTIVEMQ_ADMIN_LOGIN}: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      > "${CONF_DIR}/jetty-realm.properties"
  else
    echo "admin: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      > "${CONF_DIR}/jetty-realm.properties"
  fi
fi


# ------------------------------------------------
# 4. Update credentials.properties
# ------------------------------------------------
if [[ -f "${CONF_DIR}/credentials.properties" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" ]]; then
    USERNAME="${ACTIVEMQ_ADMIN_LOGIN}"
  else
    USERNAME="admin"
  fi

  echo "Configuring credentials.properties (overwrite mode)"
  cat > "${CONF_DIR}/credentials.properties" <<EOF
activemq.username=${USERNAME}
activemq.password=${ACTIVEMQ_ADMIN_PASSWORD}
EOF
fi

# ------------------------------------------------
# 5. Set broker name via JVM property (5.x + 6.x)
# ------------------------------------------------
export ACTIVEMQ_OPTS="$ACTIVEMQ_OPTS -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME:-$HOSTNAME}"

# ------------------------------------------------
# 6. Exec command (PID 1)
# ------------------------------------------------
exec "${ACTIVEMQ_HOME}/bin/$@"
