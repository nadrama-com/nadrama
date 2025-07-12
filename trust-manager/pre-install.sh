#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CERT_MGR_GET=$(kubectl get deployment -n system-cert-manager system-cert-manager-webhook -o json 2> /dev/null || echo '{"status": {"conditions": [{"type": "Available", "status": "False"}]}}')
CERT_MGR_STATUS="False"
if [ -n "${CERT_MGR_GET}" ]; then
    CERT_MGR_STATUS=$(echo "${CERT_MGR_GET}" | jq '.status.conditions// [] | .[] | select(.type=="Available").status' -r)
fi
if [[ "$CERT_MGR_STATUS" != "True" ]]; then
    echo "Error: system-cert-manager-webhook pod is not running/available. Please RETRY '${0} ${1}' once it has started. Exiting..."
    exit 1
fi
