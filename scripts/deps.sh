#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

# Check base + (optional) additional dependencies are installed
check_deps() {
    local additional_deps=("$@")
    local deps=(
        kubectl
        helm
        helmfile
        jq
        yq
    )
    if [[ ${#additional_deps[@]} -gt 0 ]]; then
        deps+=("${additional_deps[@]}")
    fi
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Error: $dep command not found. Please install '$dep' first. Exiting..."
            exit 1
        fi
    done
}

# Check setup was run
check_setup() {
    if [ ! -d "${CURRENT}/_values" ]; then
        echo "Error: ${CURRENT}/_values directory not found. Please run setup.sh first. Exiting..."
        exit 1
    fi
    # validate cluster type in platform values file
    if [ ! -f "${CURRENT}/_values/platform.yaml" ]; then
        echo "Error: platform.yaml not found in _values directory. Please run setup.sh first. Exiting..."
        exit 1
    fi
    CLUSTER_TYPE=$(yq '.platform.cluster.type' "${CURRENT}/_values/platform.yaml")
    if [[ "${CLUSTER_TYPE}" != "nadrama" && "${CLUSTER_TYPE}" != "eks" ]]; then
        echo "Error: Invalid cluster type '${CLUSTER_TYPE}' found in _values/platform.yaml. Valid options: nadrama, eks"
        exit 1
    fi
}
