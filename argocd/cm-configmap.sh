#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CM_NAME=argocd-cm
CM_NS=system-argocd

# Exit early if configmap already exists
kubectl get configmap -n "${CM_NS}" "${CM_NAME}" &>/dev/null && exit 0

# Check ingress hostname was loaded from values file
if [ -z "$INGRESS_HOSTNAME" ]; then
  echo "INGRESS_HOSTNAME is not loaded from values.yaml. Please run setup.sh"
  exit 1
fi

# Load configmap template, replace vars, and apply to cluster
CM_CONFIGMAP=$(cat "${CURRENT}/argocd/cm-configmap.yaml"| sed "s/local.env.cool/${INGRESS_HOSTNAME}/g")
echo "${CM_CONFIGMAP}" | kubectl apply -n "${CM_NS}" -f -
