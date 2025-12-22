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
# 3. Set broker name via JVM property (5.x + 6.x)
# ------------------------------------------------

# Inject JVM system property (picked up by activemq.xml)
export ACTIVEMQ_OPTS="$ACTIVEMQ_OPTS -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME:-$HOSTNAME}"



# ------------------------------------------------
# 4. Exec command (PID 1)
# ------------------------------------------------
exec "${ACTIVEMQ_HOME}/bin/$@"
