#!/usr/bin/env bash
set -e

ACTIVEMQ_HOME=$1

# Remove standard user from access web console
sed -i "s/user: user, user//g" ${ACTIVEMQ_HOME}/conf/jetty-realm.properties
# Remove guest from accessing broker
sed -i "s/guest.*//g" ${ACTIVEMQ_HOME}/conf/credentials.properties
# Allow all connections in jetty
sed -i "s/127.0.0.1/0.0.0.0/g" ${ACTIVEMQ_HOME}/conf/jetty.xml

# Change admin password if set via env variable
if [ ! -z "${ACTIVEMQ_ADMIN_LOGIN}" ] && [ ! -z "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
  sed -i "s/admin=.*/"${ACTIVEMQ_ADMIN_LOGIN}"="${ACTIVEMQ_ADMIN_PASSWORD}"/g" ${ACTIVEMQ_HOME}/conf/users.properties
  sed -i "s/admin.*/"${ACTIVEMQ_ADMIN_LOGIN}": "${ACTIVEMQ_ADMIN_PASSWORD}", admin/g" ${ACTIVEMQ_HOME}/conf/jetty-realm.properties
  sed -i "s/activemq.username=.*/activemq.username="${ACTIVEMQ_ADMIN_LOGIN}"/g" ${ACTIVEMQ_HOME}/conf/credentials.properties
  sed -i "s/activemq.password=.*/activemq.password="${ACTIVEMQ_ADMIN_PASSWORD}"/g" ${ACTIVEMQ_HOME}/conf/credentials.properties
elif [ ! -z "${ACTIVEMQ_ADMIN_PASSWORD}" ]; then
  sed -i "s/admin=.*/admin="${ACTIVEMQ_ADMIN_PASSWORD}"/g" ${ACTIVEMQ_HOME}/conf/users.properties
  sed -i "s/admin.*/admin: "${ACTIVEMQ_ADMIN_PASSWORD}", admin/g" ${ACTIVEMQ_HOME}/conf/jetty-realm.properties
fi

# Set broker (hostname) name
if [ ! -z "${ACTIVEMQ_BROKER_NAME}" ]; then
  sed -i "s/brokerName=\"localhost\"/brokerName=\""${ACTIVEMQ_BROKER_NAME}"\"/g" ${ACTIVEMQ_HOME}/conf/activemq.xml
fi

$ACTIVEMQ_HOME/bin/activemq console &

# Function activemq_stop to gracefully stop ActiveMQ
function activemq_stop {
  echo "Stopping ActiveMQ gracefully"
  $ACTIVEMQ_HOME/bin/activemq stop
  exit 0
}

#Set the trap to call the activemq_stop function when SIGTERM is received
trap activemq_stop SIGTERM

wait
