#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CM_NAME=argocd-cm
CM_NS=system-argocd

CURRENT=$(dirname "$(readlink -f "$0")")

# Exit early if configmap already exists
#kubectl get configmap -n "${CM_NS}" "${CM_NAME}" &>/dev/null && exit 0

# Check argocd domain was loaded from values file
if [ -z "${ARGOCD_DOMAIN}" ]; then
  echo "ARGOCD_DOMAIN is not loaded from values.yaml. Please run setup.sh"
  exit 1
fi

# Load configmap template, replace vars, and apply to cluster
CM_CONFIGMAP=$(cat "${CURRENT}/cm-configmap.yaml"| sed "s/argocd.local.env.cool/${ARGOCD_DOMAIN}/g")
echo "${CM_CONFIGMAP}" | kubectl apply -n "${CM_NS}" -f -
