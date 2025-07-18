#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")
source "${CURRENT}/config.sh"

kubectl patch service kubernetes -n default --type='merge' -p='{"spec":{"ipFamilyPolicy":"PreferDualStack","ipFamilies":["IPv4","IPv6"],"clusterIPs":["198.18.0.1","fdc6::1"]}}'
kubectl label namespace default app.kubernetes.io/managed-by=Helm --overwrite
kubectl annotate namespace default meta.helm.sh/release-name=system-namespaces meta.helm.sh/release-namespace=system-cluster --overwrite
CLUSTER_NS_EXISTS=$(kubectl get namespace system-cluster -o name || echo "Error")
if [[ "${CLUSTER_NS_EXISTS}" != "namespace/system-cluster" ]]; then
    echo "Creating system-cluster namespace..."
    kubectl create namespace system-cluster
fi

# ensure any hooks are restored to fail closed, even on error
trap 'patch_hooks Fail cert-manager && patch_hooks Fail trust-manager && echo "Cleanup complete"' EXIT

# install charts
for CHART in "${INSTALL_CHARTS[@]}"; do
    echo "Installing ${CHART}..."
    source "${CURRENT}/vars.sh"
    if [ -f "${CURRENT}/${CHART}/pre-install.sh" ]; then
        "${CURRENT}/${CHART}/pre-install.sh"
    fi
    if [[ "$CHART" == "argocd" ]] || [[ "$CHART" == "trust-manager" ]]; then
        patch_hooks Ignore cert-manager
    elif [[ "$CHART" == "trust-bundles" ]] then
        patch_hooks Ignore trust-manager
    fi
    CMD="helm upgrade --install
        ${RELEASE_NAME}
        ./${CHART}
        --dependency-update
        --no-hooks
        --namespace ${NS_NAME}
        -f ${CURRENT}/values.yaml
        ${CRD_FLAG}"
    echo "${CMD}"
    ${CMD}
    echo "${CHART} installed."
    echo ""
done
