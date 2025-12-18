#!/usr/bin/env bash
set -e

ACTIVEMQ_HOME="$1"

if [[ -z "$ACTIVEMQ_HOME" ]]; then
  echo "ERROR: ACTIVEMQ_HOME not provided"
  exit 1
fi

CONF_DIR="${ACTIVEMQ_HOME}/conf"

echo "Using ACTIVEMQ_HOME=${ACTIVEMQ_HOME}"

# ------------------------------------------------
# 1. Allow remote access to web console (Jetty)
# ------------------------------------------------
if [[ -f "${CONF_DIR}/jetty.xml" ]]; then
  sed -i 's/127.0.0.1/0.0.0.0/g' "${CONF_DIR}/jetty.xml"
fi

# ------------------------------------------------
# 2. Ensure JAAS login.config exists
# ------------------------------------------------
if [[ ! -f "${CONF_DIR}/login.config" ]]; then
  cat > "${CONF_DIR}/login.config" <<'EOF'
activemq {
  org.apache.activemq.jaas.PropertiesLoginModule required
    org.apache.activemq.jaas.properties.user="users.properties"
    org.apache.activemq.jaas.properties.group="groups.properties";
};
EOF
fi

# ------------------------------------------------
# 3. Enable JAAS plugin in ActiveMQ 5.x
# (6.x already has it)
# ------------------------------------------------
if ! grep -q "jaasAuthenticationPlugin" "${CONF_DIR}/activemq.xml"; then
  if grep -q "<plugins>" "${CONF_DIR}/activemq.xml"; then
    sed -i '/<plugins>/a\
    <jaasAuthenticationPlugin configuration="activemq"/>' \
      "${CONF_DIR}/activemq.xml"
  else
    sed -i '/<\/broker>/i\
  <plugins>\
    <jaasAuthenticationPlugin configuration="activemq"/>\
  </plugins>' \
      "${CONF_DIR}/activemq.xml"
  fi
fi

# ------------------------------------------------
# 4. Configure admin user via JAAS (non-destructive)
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then

  USERS_FILE="${CONF_DIR}/users.properties"
  GROUPS_FILE="${CONF_DIR}/groups.properties"

  touch "${USERS_FILE}" "${GROUPS_FILE}"

  # Remove default admin and existing user entry
  sed -i '/^admin=/d' "${USERS_FILE}"
  sed -i "/^${ACTIVEMQ_ADMIN_LOGIN}=.*/d" "${USERS_FILE}"
  echo "${ACTIVEMQ_ADMIN_LOGIN}=${ACTIVEMQ_ADMIN_PASSWORD}" >> "${USERS_FILE}"

  # ----------------------------
  # Groups: remove default admin and set target admin exactly
  # ----------------------------
  # Remove any existing default or target admin from admins line
  sed -i -E '/^admins=/{
    s/(^|,)admin(,|$)//g
    s/(^|,)'"${ACTIVEMQ_ADMIN_LOGIN}"'(,|$)//g
    s/,,+/,/g
    s/^admins=,*/admins=/
    s/,$//
  }' "${GROUPS_FILE}"

  # Ensure admins line contains only the target admin
  if grep -q '^admins=' "${GROUPS_FILE}"; then
    sed -i "s/^admins=.*/admins=${ACTIVEMQ_ADMIN_LOGIN}/" "${GROUPS_FILE}"
  else
    echo "admins=${ACTIVEMQ_ADMIN_LOGIN}" >> "${GROUPS_FILE}"
  fi
fi

# ------------------------------------------------
# 5. Secure Jetty realm for web console (ActiveMQ 5.x only)
# ------------------------------------------------
JETTY_REALM="${CONF_DIR}/jetty-realm.properties"
CREDENTIALS_FILE="${CONF_DIR}/credentials.properties"

# ActiveMQ 5.x has jetty-realm.properties
# ActiveMQ 6.x does not
if [[ -f "${JETTY_REALM}" ]]; then
  echo "ActiveMQ 5.x detected – securing Jetty realm"

  # Remove default 'user' role access
  sed -i 's/^user:.*//g' "${JETTY_REALM}"

  if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
    # Remove any existing admin entry
    sed -i '/^admin:/d' "${JETTY_REALM}"
    sed -i "/^${ACTIVEMQ_ADMIN_LOGIN}:/d" "${JETTY_REALM}"

    # Add target admin
    echo "${ACTIVEMQ_ADMIN_LOGIN}: ${ACTIVEMQ_ADMIN_PASSWORD}, admin" >> "${JETTY_REALM}"
  fi

  # Broker credentials file exists only in 5.x
  if [[ -f "${CREDENTIALS_FILE}" ]]; then
    sed -i '/^guest/d' "${CREDENTIALS_FILE}"

    if [[ -n "${ACTIVEMQ_ADMIN_LOGIN}" && -n "${ACTIVEMQ_ADMIN_PASSWORD}" ]]; then
      sed -i "s/^activemq.username=.*/activemq.username=${ACTIVEMQ_ADMIN_LOGIN}/" "${CREDENTIALS_FILE}" || true
      sed -i "s/^activemq.password=.*/activemq.password=${ACTIVEMQ_ADMIN_PASSWORD}/" "${CREDENTIALS_FILE}" || true
    fi
  fi
else
  echo "ActiveMQ 6.x detected – skipping Jetty realm hardening"
fi

# ------------------------------------------------
# 6. Set broker name (5.x + 6.x)
# ------------------------------------------------
if [[ -n "${ACTIVEMQ_BROKER_NAME}" ]]; then
  sed -i \
    "s/brokerName=\"localhost\"/brokerName=\"${ACTIVEMQ_BROKER_NAME}\"/g" \
    "${CONF_DIR}/activemq.xml"
fi

# ------------------------------------------------
# 6. Start ActiveMQ
# ------------------------------------------------
"${ACTIVEMQ_HOME}/bin/activemq" console &

# ------------------------------------------------
# 7. Graceful shutdown handling
# ------------------------------------------------
function activemq_stop {
  echo "Stopping ActiveMQ gracefully"
  "${ACTIVEMQ_HOME}/bin/activemq" stop
  exit 0
}

trap activemq_stop SIGTERM
wait
