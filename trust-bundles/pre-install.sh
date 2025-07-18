#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")

if [[ "$FORCE_NO_HOOKS" != "true" ]]; then
    TRUST_MGR_GET=$(kubectl get deployment -n system-trust-manager system-trust-manager -o json 2> /dev/null || echo '{"status": {"conditions": [{"type": "Available", "status": "False"}]}}')
    TRUST_MGR_STATUS="False"
    if [ -n "${TRUST_MGR_GET}" ]; then
        TRUST_MGR_STATUS=$(echo "${TRUST_MGR_GET}" | jq '.status.conditions// [] | .[] | select(.type=="Available").status' -r)
    fi
    if [[ "$TRUST_MGR_STATUS" != "True" ]]; then
        echo "Error: system-trust-manager pod is not running/available. Please RETRY '${0} ${1}' once it has started. Exiting..."
        exit 1
    fi
fi
