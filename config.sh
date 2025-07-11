#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

# static config (note: chart order is critical)

SYSTEM_CORE_CRD_CHARTS=(
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
