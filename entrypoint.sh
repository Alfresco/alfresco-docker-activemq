#!/usr/bin/env bash
set -e

# ------------------------------------------------
# 1. Allow remote access to web console (Jetty)
# ------------------------------------------------
if [[ -f "${ACTIVEMQ_HOME}/conf/jetty.xml" ]]; then
  sed -i 's/127.0.0.1/0.0.0.0/g' "${ACTIVEMQ_HOME}/conf/jetty.xml"
fi

# ------------------------------------------------
# 2. Configure admin user via JAAS (non-destructive)
# ------------------------------------------------
# Case 1: Both ADMIN_LOGIN and ADMIN_PASSWORD → custom admin
if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  sed -i '/^admin=/d' "${ACTIVEMQ_HOME}/conf/users.properties"
  sed -i "/^${ACTIVEMQ_ADMIN_LOGIN}=.*/d" "${ACTIVEMQ_HOME}/conf/users.properties"
  echo "${ACTIVEMQ_ADMIN_LOGIN}=${ACTIVEMQ_ADMIN_PASSWORD}" >> "${ACTIVEMQ_HOME}/conf/users.properties"

# Case 2: Only ADMIN_PASSWORD → default admin
elif [[ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
  sed -i '/^admin=/d' "${ACTIVEMQ_HOME}/conf/users.properties"
  echo "admin=${ACTIVEMQ_ADMIN_PASSWORD}" >> "${ACTIVEMQ_HOME}/conf/users.properties"
fi

# ------------------------------------------------
# 3. ActiveMQ 5.x – configure jetty-realm.properties
# ------------------------------------------------

if [[ -f "${ACTIVEMQ_HOME}/conf/jetty-realm.properties" ]]; then
  echo "ActiveMQ 5.x detected – configuring admin at runtime"
  # Remove the default user entry if present
  sed -i '/^user: user, user/d' "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"

  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
    # Remove any existing admin or duplicate login entries
    sed -i "/^admin:/d" "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
    sed -i "/^${ACTIVEMQ_ADMIN_LOGIN}:/d" "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"

    # Append new admin entry
    echo "${ACTIVEMQ_ADMIN_LOGIN}: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" >> "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"

  elif [[ -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
    # Remove any existing admin entry
    sed -i "/^admin:/d" "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"

    # Append admin with new password
    echo "admin: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" >> "${ACTIVEMQ_HOME}/conf/jetty-realm.properties"
  fi
fi


# ------------------------------------------------
# 4. Update credentials.properties
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_PASSWORD}" && -f "${ACTIVEMQ_HOME}/conf/credentials.properties" ]]; then
  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" ]]; then
    USERNAME="${ACTIVEMQ_ADMIN_LOGIN}"
  else
    USERNAME="admin"
  fi

  sed -i \
    -e "s/^activemq.username=.*/activemq.username=${USERNAME}/" \
    -e "s/^activemq.password=.*/activemq.password=${ACTIVEMQ_ADMIN_PASSWORD}/" \
    "${ACTIVEMQ_HOME}/conf/credentials.properties" || true
fi

# ------------------------------------------------
# 5. Set broker name via JVM property (5.x + 6.x)
# ------------------------------------------------
export ACTIVEMQ_OPTS="$ACTIVEMQ_OPTS -Dactivemq.brokername=${ACTIVEMQ_BROKER_NAME:-$HOSTNAME}"

# ------------------------------------------------
# 6. Exec command (PID 1)
# ------------------------------------------------
exec "${ACTIVEMQ_HOME}/bin/$@"
