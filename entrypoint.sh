#!/usr/bin/env bash
set -e

# ------------------------------------------------
# Allow remote access to web console (Jetty)
# ------------------------------------------------
if [[ -f "${ACTIVEMQ_HOME}/conf/jetty.xml" ]]; then
  echo "Configuring Jetty to bind on 0.0.0.0"
  xmlstarlet ed -L \
  -N b="http://www.springframework.org/schema/beans" \
  -u "//b:bean[@id='jettyPort']/b:property[@name='host']/@value" \
  -v "0.0.0.0" \
  "${ACTIVEMQ_HOME}/conf/jetty.xml"
fi


# ------------------------------------------------
# 2. Configure admin user via JAAS (users.properties)
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    echo "${ACTIVEMQ_ADMIN_LOGIN}=${ACTIVEMQ_ADMIN_PASSWORD}" \
      > "${ACTIVEMQ_HOME}/conf/users.properties"
  else
    echo "admin=${ACTIVEMQ_ADMIN_PASSWORD}" \
      > "${ACTIVEMQ_HOME}/conf/users.properties"
  fi
fi

# ------------------------------------------------
# 2b. Grant admin role (groups.properties) – REQUIRED for 6.x
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" && -f "${ACTIVEMQ_HOME}/conf/groups.properties" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    echo "admins=${ACTIVEMQ_ADMIN_LOGIN}" \
      > "${ACTIVEMQ_HOME}/conf/groups.properties"
  else
    echo "admins=admin" \
      > "${ACTIVEMQ_HOME}/conf/groups.properties"
  fi
fi

# ------------------------------------------------
# 3. ActiveMQ 5.x – configure jetty-realm.properties
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD:-}" && -f "${ACTIVEMQ_HOME}/conf/jetty-realm.properties" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN:-}" ]]; then
    echo "${ACTIVEMQ_ADMIN_LOGIN}: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      > "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  else
    echo "admin: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      > "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  fi
fi

# ------------------------------------------------
# 4. Update credentials.properties
# ------------------------------------------------
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

# ------------------------------------------------
# 5. Set broker name via JVM property (5.x + 6.x)
# ------------------------------------------------
export ACTIVEMQ_OPTS="${ACTIVEMQ_OPTS:-} -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME:-$HOSTNAME}"

# ------------------------------------------------
# 6. Exec (PID 1)
# ------------------------------------------------
exec "${ACTIVEMQ_HOME}/bin/$@"
