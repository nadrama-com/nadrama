#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")

# static config (note: chart order is critical)

SYSTEM_CORE_CRD_CHARTS=(
    snapshot-crds
    cilium-crds
    cert-manager-crds
    trust-manager-crds
    gateway-api-crds
    traefik-crds
    argocd-crds
    sealed-secrets-crds
    # TODO: cluster-api-crds
)
SYSTEM_CORE_APP_CHARTS=(
    namespaces
    rbac
    cilium
    coredns
    argocd
    cert-manager
    trust-manager
    traefik
    trust-bundles
    sealed-secrets
    # TODO: cluster-api
    apps
)
SYSTEM_ADDON_CHARTS=(
)
DEFAULT_CHARTS=(
    nadrama-hello
)

SYSTEM_CORE_CHARTS=(${SYSTEM_CORE_CRD_CHARTS[@]} ${SYSTEM_CORE_APP_CHARTS[@]})
SYSTEM_CHARTS=(${SYSTEM_CORE_CHARTS[@]} ${SYSTEM_ADDON_CHARTS[@]})
INSTALL_CHARTS=(${SYSTEM_CORE_CHARTS[@]} ${DEFAULT_CHARTS[@]})

# check setup was run
if [ ! -f "${CURRENT}/values.yaml" ]; then
    echo "Error: values.yaml file not found. Please run setup.sh first. Exiting..."
    exit 1
fi

# runtime dependencies

deps=(
    jq
    kubectl
    helm
    openssl
    base64
    head
    grep
)
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "Error: $dep command not found. Please install '$dep' first. Exiting..."
        exit 1
    fi
done

# dynamic config

# allow specifying a single chart to install
if [[ -n "${1}" ]]; then
    if [[ ! " ${INSTALL_CHARTS[@]} " =~ " ${1} " ]]; then
        echo "Error: Chart '${1}' is not a valid chart in config.sh"
        exit 1
    fi
    INSTALL_CHARTS=("${1}")
fi

# get ingress hostname from values file using grep
INGRESS_HOSTNAME=$(grep "hostname\: " "${CURRENT}/values.yaml")
export INGRESS_HOSTNAME=${INGRESS_HOSTNAME#*: }

# get argocd domain from values file using grep
ARGOCD_DOMAIN=$(grep "domain\: " "${CURRENT}/values.yaml")
export ARGOCD_DOMAIN=${ARGOCD_DOMAIN#*: }

# validating and mutating webhooks we can enable/disable from install.sh
declare -A webhook_groups
cert_manager_hooks=(
  "mutatingwebhookconfiguration/system-cert-manager-webhook"
  "validatingwebhookconfiguration/system-cert-manager-webhook"
  "validatingwebhookconfiguration/system-cert-manager-approver-policy"
)
webhook_groups[cert-manager]=cert_manager_hooks
trust_manager_hooks=(
  "validatingwebhookconfiguration/system-trust-manager"
)
webhook_groups[trust-manager]=trust_manager_hooks
patch_hooks() {
  # only runs if FORCE_NO_HOOKS == true
  [[ "$FORCE_NO_HOOKS" != "true" ]] && return

  local policy="$1"
  local group="$2"
  local array_name="${webhook_groups[$group]}"
  [[ -z "$array_name" ]] && return
  local -n hooks="$array_name"

  echo "Setting ${group} hooks to ${policy}"
  for hook in "${hooks[@]}"; do
    echo "$hook"
    kubectl patch "$hook" --type='json' \
    -p="[{'op': 'replace', 'path': '/webhooks/0/failurePolicy', 'value': '$policy'}]" &> /dev/null || true
  done
}
