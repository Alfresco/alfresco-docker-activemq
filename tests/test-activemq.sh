#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?Image name required as first argument}"
CONTAINER="amq-runtime-test"
EXPECTED_BROKER_NAME="${EXPECTED_BROKER_NAME:-ci-broker}"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "▶ Starting ActiveMQ container..."
docker run -d \
  --name "$CONTAINER" \
  -e ACTIVEMQ_BROKER_NAME="$EXPECTED_BROKER_NAME" \
  "$IMAGE" >/dev/null

echo "▶ Waiting for broker to be ready..."
for i in {1..30}; do
  if docker exec "$CONTAINER" \
    /opt/activemq/bin/activemq query \
    --objname type=Broker,brokerName=* \
    >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# brokerName runtime verification
BROKER_NAME=$(docker exec "$CONTAINER" \
  /opt/activemq/bin/activemq query \
  --objname type=Broker,brokerName=* \
  | sed -n 's/.*brokerName=\([^,]*\).*/\1/p' | head -n1)

# Debug visibility: dump config before asserting
docker exec "$CONTAINER" env | grep ACTIVEMQ
docker exec "$CONTAINER" cat /opt/activemq/conf/activemq.xml
docker exec "$CONTAINER" /opt/activemq/bin/activemq query --objname type=Broker,brokerName=*

if [[ "$BROKER_NAME" != "$EXPECTED_BROKER_NAME" ]]; then
  echo "❌ brokerName mismatch: $BROKER_NAME (expected $EXPECTED_BROKER_NAME)"
  exit 1
fi
echo "✅ brokerName applied at runtime: $BROKER_NAME"

# JAAS authentication enforcement
echo "▶ Verifying JAAS authentication..."

# valid credentials must succeed
docker exec "$CONTAINER" \
  /opt/activemq/bin/activemq producer \
  --broker tcp://localhost:61616 \
  --user admin \
  --password admin \
  --destination queue:test \
  --message "auth-ok" \
  >/dev/null 2>&1
echo "✅ Valid credentials accepted"

# invalid credentials must fail
if docker exec "$CONTAINER" \
  /opt/activemq/bin/activemq producer \
  --broker tcp://localhost:61616 \
  --user baduser \
  --password badpass \
  --destination queue:test \
  --message "auth-fail" \
  >/dev/null 2>&1; then
  echo "❌ JAAS authentication FAILED (invalid credentials accepted)"
  exit 1
fi

echo "✅ Invalid credentials rejected"
echo "🎉 Runtime brokerName and JAAS tests passed"
