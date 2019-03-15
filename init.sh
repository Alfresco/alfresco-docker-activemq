#!/usr/bin/env bash
set -e

ACTIVEMQ_HOME=$1

# Remove standard user from access web console
sed -i "s/user: user, user//g" ${ACTIVEMQ_HOME}/conf/jetty-realm.properties
# Remove guest from accessing broker
sed -i "s/guest.*//g" ${ACTIVEMQ_HOME}/conf/credentials.properties

# Change admin password if set vie env variable
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
