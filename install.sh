#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")

# Check dependencies
deps=(
    kubectl
    helm
    helmfile
    jq
    yq
)
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "Error: $dep command not found. Please install '$dep' first. Exiting..."
        exit 1
    fi
done

# Check setup was run
if [ ! -d "${CURRENT}/_values" ]; then
    echo "Error: _values directory not found. Please run setup.sh first. Exiting..."
    exit 1
fi

# Ensure webhooks are disabled then restored on script error/cancellation
patch_webhooks() {
    local policy="$1"
    if [[ "$policy" != "Ignore" ]] && [[ "$policy" != "Fail" ]]; then
        echo "Invalid patch_webhooks policy param: $policy. Must be 'Ignore' or 'Fail'."
        exit 1
    fi
    echo "Setting webhooks to ${policy}..."
    # Restore cert-manager webhooks
    kubectl patch mutatingwebhookconfiguration/system-cert-manager-webhook --type='json' -p="[{'op': 'replace', 'path': '/webhooks/0/failurePolicy', 'value': '${policy}'}]" &> /dev/null || true
    kubectl patch validatingwebhookconfiguration/system-cert-manager-webhook --type='json' -p="[{'op': 'replace', 'path': '/webhooks/0/failurePolicy', 'value': '${policy}'}]" &> /dev/null || true
    kubectl patch validatingwebhookconfiguration/system-cert-manager-approver-policy --type='json' -p="[{'op': 'replace', 'path': '/webhooks/0/failurePolicy', 'value': '${policy}'}]" &> /dev/null || true
    # Restore trust-manager webhooks
    kubectl patch validatingwebhookconfiguration/system-trust-manager --type='json' -p="[{'op': 'replace', 'path': '/webhooks/0/failurePolicy', 'value': '${policy}'}]" &> /dev/null || true
    echo "Webhooks set to ${policy} successfully."
}
trap 'patch_webhooks Fail' EXIT
# patch_webhooks 'Ignore'

# Install specific chart if provided
if [[ -n "${1}" ]]; then
    echo "Installing specific chart: ${1}"
    helmfile --args "--skip-crds" -l "chart=${1}" sync
else
    echo "Installing all charts with helmfile..."
    helmfile --args "--skip-crds" sync
fi
