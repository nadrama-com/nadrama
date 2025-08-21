#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
# Helmfile-based replacement for uninstall.sh

set -eo pipefail

# Check dependencies
source "${CURRENT}/scripts/deps.sh"
check_deps

# Uninstall specific chart if provided
if [[ -n "${1}" ]]; then
    echo "Uninstalling specific chart: ${1}"
    helmfile -l "name=${1}" destroy
else
    echo "Uninstalling all charts with helmfile..."
    helmfile destroy
fi
