#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

SECRET_NAME="env-cool-acmedns-secret"
SECRET_NS="system-traefik"

# Exit early if secret already exists
kubectl get secret -n "${SECRET_NS}" "${SECRET_NAME}" &>/dev/null && exit 0

# Check args
if [ -z "$1" ]; then
  echo "Usage: $0 <ingress-hostname>"
  exit 1
fi
INGRESS_HOSTNAME="${1}"
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
  "${INGRESS_HOSTNAME}": {
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
kubectl apply -f - <<EOF
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
