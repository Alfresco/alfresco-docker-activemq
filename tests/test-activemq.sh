#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?Image name required as first argument}"
CONTAINER="amq-runtime-test"
EXPECTED_BROKER_NAME="${EXPECTED_BROKER_NAME:-ci-broker}"

echo "▶ Inspecting labels for image $IMAGE..."
CREATED=$(docker image inspect "$IMAGE" \
  --format '{{ index .Config.Labels "org.opencontainers.image.created" }}')

if [[ -z "$CREATED" ]]; then
  echo "❌ Image label 'org.opencontainers.image.created' is missing or empty"
  exit 1
fi
echo "✅ Image created date present: $CREATED"

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

if [[ "$BROKER_NAME" != "$EXPECTED_BROKER_NAME" ]]; then
  echo "❌ brokerName mismatch: $BROKER_NAME (expected $EXPECTED_BROKER_NAME)"
  exit 1
fi
echo "✅ brokerName applied at runtime: $BROKER_NAME"

# authentication tests with valid credentials
if ! docker exec "$CONTAINER" \
  /opt/activemq/bin/activemq producer \
  --broker tcp://localhost:61616 \
  --user admin \
  --password admin \
  --destination queue:test \
  --message "auth-ok" \
  >/dev/null 2>&1; then
  echo "❌ Valid credentials were rejected (unexpected)"
  exit 1
fi
echo "✅ Valid credentials accepted"

# authentication tests with invalid credentials(JAAS enforcement >= 6.x)
if (( ${ACTIVEMQ_VERSION%%.*} >= 6 )); then
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
  echo "✅ JAAS authentication enforced correctly (6.x+)"
else
  if ! docker exec "$CONTAINER" \
    /opt/activemq/bin/activemq producer \
    --broker tcp://localhost:61616 \
    --user baduser \
    --password badpass \
    --destination queue:test \
    --message "auth-fail" \
    >/dev/null 2>&1; then
    echo "❌ Invalid credentials were rejected (unexpected for 5.x)"
    exit 1
  fi
  echo "✅ Authentication not enforced (expected for 5.x)"
fi

echo "✅ All tests passed for image $IMAGE"
