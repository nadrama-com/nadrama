#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")
source "${CURRENT}/config.sh"

for (( idx=${#INSTALL_CHARTS[@]}-1 ; idx>=0 ; idx-- )) ; do
    CHART="${INSTALL_CHARTS[idx]}"
    echo "Uninstalling ${CHART}..."
    # prefix the helm installation release name with system- for system charts
    RELEASE_NAME="${CHART}"
    if [[ "${SYSTEM_CHARTS[*]}" =~ "${CHART}" ]]; then
        RELEASE_NAME="system-${CHART}"
    fi
    # use the chart name for namespace, prefixed with system- for system charts,
    # and for CRD charts, namespaces, and cluster use system-cluster,
    # and for nadrama-hello use default.
    NS_NAME="${CHART}"
    if [[ "${CHART}" = "namespaces" ]] || [[ "${CHART}" = "cluster" ]] || [[ "${CHART}" = *-crds ]]; then
        NS_NAME="system-cluster"
    elif [[ "${CHART}" = "nadrama-hello" ]]; then
        NS_NAME="default"
    elif [[ "${SYSTEM_CHARTS[*]}" =~ "${CHART}" ]]; then
        NS_NAME="system-${CHART}"
    fi
    CMD="helm uninstall
        ${RELEASE_NAME}
        --namespace ${NS_NAME}
        --no-hooks"
    echo "${CMD}"
    ${CMD}
    echo "${CHART} uninstalled."
done
