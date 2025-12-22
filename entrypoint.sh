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

  USERS_FILE="${ACTIVEMQ_HOME}/conf/users.properties"
  GROUPS_FILE="${ACTIVEMQ_HOME}/conf/groups.properties"

  touch "${USERS_FILE}" "${GROUPS_FILE}"

  # Remove default admin and existing user entry
  sed -i '/^admin=/d' "${USERS_FILE}"
  sed -i "/^${ACTIVEMQ_ADMIN_LOGIN}=.*/d" "${USERS_FILE}"
  echo "${ACTIVEMQ_ADMIN_LOGIN}=${ACTIVEMQ_ADMIN_PASSWORD}" >> "${USERS_FILE}"

  # ----------------------------
  # Groups: remove default admin and set target admin exactly
  # ----------------------------
  sed -i -E '/^admins=/{
    s/(^|,)admin(,|$)//g
    s/(^|,)'"${ACTIVEMQ_ADMIN_LOGIN}"'(,|$)//g
    s/,,+/,/g
    s/^admins=,*/admins=/
    s/,$//
  }' "${GROUPS_FILE}"

  if grep -q '^admins=' "${GROUPS_FILE}"; then
    sed -i "s/^admins=.*/admins=${ACTIVEMQ_ADMIN_LOGIN}/" "${GROUPS_FILE}"
  else
    echo "admins=${ACTIVEMQ_ADMIN_LOGIN}" >> "${GROUPS_FILE}"
  fi
fi

# ------------------------------------------------
# 3. ActiveMQ 5.x – configure admin at runtime
# ------------------------------------------------

# ActiveMQ 5.x detection (jetty-realm.properties exists only in 5.x)
if [ -f "${ACTIVEMQ_HOME}/conf/jetty-realm.properties" ]; then
  echo "ActiveMQ 5.x detected – configuring admin at runtime"

  if [ -n "${ACTIVEMQ_ADMIN_LOGIN}" ] && [ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
    ADMIN_USER="${ACTIVEMQ_ADMIN_LOGIN}"
    ADMIN_PASS="${ACTIVEMQ_ADMIN_PASSWORD}"

    # ---- credentials.properties (5.x only) ----
    if [ -f "${ACTIVEMQ_HOME}/conf/credentials.properties" ]; then
      sed -i "s/^activemq.username=.*/activemq.username=${ADMIN_USER}/" "${ACTIVEMQ_HOME}/conf/credentials.properties" || true
      sed -i "s/^activemq.password=.*/activemq.password=${ADMIN_PASS}/" "${ACTIVEMQ_HOME}/conf/credentials.properties" || true
    fi

  elif [ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
    ADMIN_USER="admin"
    ADMIN_PASS="${ACTIVEMQ_ADMIN_PASSWORD}"

    if [ -f "${ACTIVEMQ_HOME}/conf/credentials.properties" ]; then
      sed -i "s/^activemq.username=.*/activemq.username=${ADMIN_USER}/" "${ACTIVEMQ_HOME}/conf/credentials.properties" || true
      sed -i "s/^activemq.password=.*/activemq.password=${ADMIN_PASS}/" "${ACTIVEMQ_HOME}/conf/credentials.properties" || true
    fi

  else
    # Case: no env → default Jetty admin only, leave credentials.properties as-is
    ADMIN_USER="admin"
    ADMIN_PASS="admin"
  fi

  echo "Configuring admin user: ${ADMIN_USER}"

  # ---- jetty-realm.properties ----
  sed -i "/^${ADMIN_USER}:/d" "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  echo "${ADMIN_USER}: ${ADMIN_PASS}, admin" >> "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"

else
  echo "ActiveMQ 6.x detected – skipping admin configuration"
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
