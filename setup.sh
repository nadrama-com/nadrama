#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")

if [ -z "${1}" ]; then
    echo "Usage: $0 <ingress-hostname>"
    exit 1
fi
INGRESS_HOSTNAME="${1}"

if [ -f "${CURRENT}/values.yaml" ]; then
    echo "${CURRENT}/values.yaml file already exists. Please remove it before running this script."
    exit 1
fi

INGRESS_PORT=""
if [[ "${INGRESS_HOSTNAME}" = "local.env.cool" ]]; then
    # Nadrama dev-specific override
    INGRESS_PORT=":4433"
fi

cat - > "${CURRENT}/values.yaml" <<EOF
nadrama:
  ingress:
    hostname: ${INGRESS_HOSTNAME}
    letsencrypt: false
argo-cd:
  global:
    domain: argocd.${INGRESS_HOSTNAME}${INGRESS_PORT}
EOF

echo "Setup complete."
