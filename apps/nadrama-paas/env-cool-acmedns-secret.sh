#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

SECRET_NAME="system-env-cool-acmedns-secret"
# note: must be the same as where the certificate is requested
SECRET_NS="system-traefik"

CURRENT=$(dirname "$(readlink -f "$0")")

# Exit early if secret already exists
kubectl get secret -n "${SECRET_NS}" "${SECRET_NAME}" &> /dev/null && echo "${SECRET_NAME} exists." && exit 0 || true

# Extract cluster fqdn from values file
CLUSTER_FQDN=$(yq eval '.nadrama.paas.cluster.fqdn' "${CURRENT}/../../_values/nadrama-paas.yaml")

# Check cluster fqdn was loaded from values file
if [ -z "$CLUSTER_FQDN" ]; then
  echo "CLUSTER_FQDN is not loaded from _values/nadrama-paas.yaml. Please run setup.sh"
  exit 1
fi

echo "Creating ${SECRET_NAME} secret in ${SECRET_NS}..."

# Generate random password
RANDOM_PASSWORD=$(openssl rand -base64 200 | tr -dc 'a-zA-Z0-9_-' | head -c 100)

# eg.env.cool:
#   username: "" # cluster slug
#   password: "" # random value
#   fulldomain: "" # can be empty
#   subdomain: "" # cluster id
#   allowfrom: []
JSON_CONTENT=$(
cat - <<EOF
{
  "${CLUSTER_FQDN}": {
    "username": "local",
    "password": "${RANDOM_PASSWORD}",
    "fulldomain": "",
    "subdomain": "cls0000000001r010000000000000",
    "allowfrom": []
  }
}
EOF
)

# Generate password and create secret
ENCODED_JSON_CONTENT=$(echo "${JSON_CONTENT}" | jq . | base64)
kubectl apply -n "${SECRET_NS}" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${SECRET_NS}
  labels:
    app.kubernetes.io/name: ${SECRET_NAME}
type: Opaque
data:
  acmedns.json: ${ENCODED_JSON_CONTENT}
EOF
