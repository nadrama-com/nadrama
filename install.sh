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

for CHART in "${INSTALL_CHARTS[@]}"; do
    echo "Installing ${CHART}..."
    source "${CURRENT}/vars.sh"
    if [[ "${CHART}" == "argocd" ]]; then
        ${CURRENT}/argocd/redis-password.sh
        # Create ConfigMap with values.yaml content for ArgoCD to use
        CONFIGMAP_EXISTS=$(kubectl get configmap nadrama-values -n system-argocd -o name 2>/dev/null || echo "")
        if [[ -z "${CONFIGMAP_EXISTS}" ]]; then
            echo "Creating nadrama-values ConfigMap..."
            kubectl create configmap nadrama-values --from-file=values.yaml="${CURRENT}/values.yaml" -n system-argocd
        else
            echo "Updating nadrama-values ConfigMap..."
            kubectl create configmap nadrama-values --from-file=values.yaml="${CURRENT}/values.yaml" -n system-argocd --dry-run=client -o yaml | kubectl apply -f -
        fi
    elif [[ "${CHART}" == "traefik" ]]; then
        ${CURRENT}/traefik/env-cool-acmedns-secret.sh ${NADRAMA_CHARTS_INGRESS_HOSTNAME}
    elif [[ "${CHART}" == "trust-manager" ]]; then
        CERT_MGR_GET=$(kubectl get deployment -n system-cert-manager system-cert-manager-webhook -o json 2> /dev/null || echo '{"status": {"conditions": [{"type": "Available", "status": "False"}]}}')
        CERT_MGR_STATUS="False"
        if [ -n "${CERT_MGR_GET}" ]; then
            CERT_MGR_STATUS=$(echo "${CERT_MGR_GET}" | jq '.status.conditions// [] | .[] | select(.type=="Available").status' -r)
        fi
        if [[ "$CERT_MGR_STATUS" != "True" ]]; then
            echo "Error: system-cert-manager-webhook pod is not running/available. Please RETRY '${0} ${1}' once it has started. Exiting..."
            exit 1
        fi
    elif [[ "${CHART}" == "trust-bundles" ]]; then
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
done
