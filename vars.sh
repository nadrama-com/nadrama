#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

# Determine chart vars
if [ -z "${CHART}" ]; then
    echo "Error: CHART variable is not set." >&2
    exit 1
fi

# prefix the helm installation release name with system- for system charts
RELEASE_NAME="${CHART}"
if [[ "${SYSTEM_CHARTS[*]}" =~ "${CHART}" ]]; then
    RELEASE_NAME="system-${CHART}"
fi

# use the chart name for namespace, prefixed with system- for system charts,
# and for CRD charts, namespaces, and rbac use system-cluster,
# and for nadrama-hello use default.
NS_NAME="${CHART}"
if [[ "${CHART}" = "namespaces" ]] || [[ "${CHART}" = "rbac" ]] || [[ "${CHART}" = *-crds ]]; then
    NS_NAME="system-cluster"
elif [[ "${CHART}" = "nadrama-hello" ]]; then
    NS_NAME="default"
elif [[ "${SYSTEM_CHARTS[*]}" =~ "${CHART}" ]]; then
    NS_NAME="system-${CHART}"
fi

# skip CRDs when not a CRD chart
CRD_FLAG=""
if [[ "${CHART}" != *-crds ]]; then
    CRD_FLAG="--skip-crds"
fi
