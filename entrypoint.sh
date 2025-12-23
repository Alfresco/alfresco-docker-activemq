#!/usr/bin/env bash
set -e

# ------------------------------------------------
# 1. Allow remote access to web console (Jetty)
# ------------------------------------------------
if [[ -f "${ACTIVEMQ_HOME}/conf/jetty.xml" ]]; then
  sed -i 's/127.0.0.1/0.0.0.0/g' "${ACTIVEMQ_HOME}/conf/jetty.xml"
fi

# 2. Configure admin user via JAAS (non-destructive)
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  sed -i '/^admin=/d' "${ACTIVEMQ_HOME}/conf/users.properties"
  sed -i "/^${ACTIVEMQ_ADMIN_LOGIN}=.*/d" "${ACTIVEMQ_HOME}/conf/users.properties"
  echo "${ACTIVEMQ_ADMIN_LOGIN}=${ACTIVEMQ_ADMIN_PASSWORD}" >> "${ACTIVEMQ_HOME}/conf/users.properties"
fi

# ------------------------------------------------
# 3. ActiveMQ 5.x – configure admin at runtime
# ------------------------------------------------

# ActiveMQ 5.x detection (jetty-realm.properties exists only in 5.x)
if [ -f "${ACTIVEMQ_HOME}/conf/jetty-realm.properties" ]; then
  echo "ActiveMQ 5.x detected – configuring admin at runtime"
  # Case 1: ADMIN_LOGIN + ADMIN_PASSWORD
  if [ -n "${ACTIVEMQ_ADMIN_LOGIN}" ] && [ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
    sed -i \
      -e '/^admin:/d' \
      -e "/^${ACTIVEMQ_ADMIN_LOGIN}:/d" \
      -e "\$a${ACTIVEMQ_ADMIN_LOGIN}: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"

  # Case 2: ADMIN_PASSWORD only (match old script)
  elif [ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
    sed -i \
      -e '/^admin:/d' \
      -e "\$aadmin: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" \
      "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  fi
fi

if [ -n "${ACTIVEMQ_ADMIN_LOGIN}" ] && [ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
  if [ -f "${ACTIVEMQ_HOME}/conf/credentials.properties" ]; then
    sed -i \
      -e "s/^activemq.username=.*/activemq.username=${ACTIVEMQ_ADMIN_LOGIN}/" \
      -e "s/^activemq.password=.*/activemq.password=${ACTIVEMQ_ADMIN_PASSWORD}/" \
      "${ACTIVEMQ_HOME}/conf/credentials.properties" || true
  fi
fi


# ------------------------------------------------
# 4. Set broker name via JVM property (5.x + 6.x)
# ------------------------------------------------

# Inject JVM system property (picked up by activemq.xml)
export ACTIVEMQ_OPTS="$ACTIVEMQ_OPTS -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME:-$HOSTNAME}"


# ------------------------------------------------
# 5. Exec command (PID 1)
# ------------------------------------------------
exec "${ACTIVEMQ_HOME}/bin/$@"
