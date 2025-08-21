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
