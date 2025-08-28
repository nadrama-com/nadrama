#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")

# Check dependencies
source "${CURRENT}/scripts/deps.sh"
check_deps

# Check params
if [ -z "${1}" ]; then
    echo "Usage: $0 <ingress-hostname>"
    exit 1
fi
INGRESS_HOSTNAME="${1}"
INGRESS_PORT=""
if [[ "${INGRESS_HOSTNAME}" = "local.env.cool" ]]; then
    # Nadrama dev-specific override
    INGRESS_PORT=":4433"
fi

# Prevent overwriting existing values files
if [ -d "${CURRENT}/_values" ]; then
    echo "${CURRENT}/_values directory already exists. Please remove it before running this script."
    exit 1
fi

# Create _values directory
mkdir -p "${CURRENT}/_values"

# Default value for all CSI drivers apps
CSI_ALL="false"
if [[ "${CSI_ALL}" == "true" ]] || [[ "${CSI_ALL}" == 1 ]]; then
    CSI_ALL="true"
fi

# Define network settings
IP_FAMILY_POLICY="PreferDualStack"
IP_FAMILIES_IPV4='- "IPv4"'
IP_FAMILIES_IPV6='- "IPv6"'

# Create values files

cat > "${CURRENT}/_values/platform.yaml" <<EOF
platform:
  system:
    # CRDs
    crds:
      cilium-crds:
        enabled: true
      snapshot-crds:
        enabled: true
      cert-manager-crds:
        enabled: true
      trust-manager-crds:
        enabled: true
      gateway-api-crds:
        enabled: true
      traefik-crds:
        enabled: true
      argocd-crds:
        enabled: true
      sealed-secrets-crds:
        enabled: true
      external-secrets-crds:
        enabled: true
    # Apps
    apps:
      namespaces:
        enabled: true
      rbac:
        enabled: true
      cilium:
        enabled: true
      coredns:
        enabled: true
      snapshot:
        enabled: true
      csi-aws-ebs:
        enabled: ${CSI_ALL}
      cert-manager:
        enabled: true
      trust-manager:
        enabled: true
      traefik:
        enabled: true
      trust-bundles:
        enabled: true
      sealed-secrets:
        enabled: true
      argocd:
        enabled: true
      nadrama-paas:
        enabled: false
EOF

cat > "${CURRENT}/_values/coredns.yaml" <<EOF
coredns:
  service:
    clusterIP: "198.19.255.254"
    clusterIPs:
      - "198.19.255.254"
      - "fdc6::ffff"
    ipFamilyPolicy: "${IP_FAMILY_POLICY}"
    ipFamilies:
      ${IP_FAMILIES_IPV4}
      ${IP_FAMILIES_IPV6}
#   # loads the upstream nameserver config from systemd-resolve
#   # see https://coredns.io/plugins/loop/#troubleshooting-loops-in-kubernetes-clusters
#   extraVolumes:
#     - name: systemd-resolve
#       hostPath:
#         path: /run/systemd/resolve/resolv.conf
#         type: File
#   extraVolumeMounts:
#     - name: systemd-resolve
#       mountPath: /etc/resolv.conf
#       readOnly: true
EOF

cat > "${CURRENT}/_values/csi-aws-ebs.yaml" <<EOF
# aws-ebs-csi-driver:
#   controller:
#     podAnnotations:
#       iam.amazonaws.com/role: "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/nadrama-YOUR_CLUSTER_SLUG-ebs-csi"
EOF

cat > "${CURRENT}/_values/cert-manager.yaml" <<EOF
nadrama:
  cert-manager:
    clusterCA:
      commonName: "${INGRESS_HOSTNAME}"
    traefikDefaultCertificatePolicy:
      allowedHostname: "${INGRESS_HOSTNAME}"
EOF

cat > "${CURRENT}/_values/nadrama-paas.yaml" <<EOF
nadrama:
  paas:
    cluster:
      fqdn: "${INGRESS_HOSTNAME}"
EOF

cat > "${CURRENT}/_values/traefik.yaml" <<EOF
nadrama:
  traefik:
    # defaultCertificateSecret: system-traefik-casigned-certificate-secret
    certificates:
      dnsNames:
      - "${INGRESS_HOSTNAME}"
      - "*.${INGRESS_HOSTNAME}"
      selfsigned:
        issuerRef:
          name: system-selfsigned-clusterissuer
      casigned:
        issuerRef:
          # name: system-env-cool-clusterissuer
traefik:
  service:
    spec:
      clusterIP: "198.18.0.2"
      clusterIPs:
        - "198.18.0.2"
        - "fdc6::2"
    ipFamilyPolicy: "${IP_FAMILY_POLICY}"
    ipFamilies:
      ${IP_FAMILIES_IPV4}
      ${IP_FAMILIES_IPV6}
EOF

cat > "${CURRENT}/_values/argocd.yaml" <<EOF
nadrama:
  argocd:
    hostname: "argocd.${INGRESS_HOSTNAME}"
argo-cd:
  global:
    dualStack:
      ipFamilyPolicy: "${IP_FAMILY_POLICY}"
      ipFamilies:
        ${IP_FAMILIES_IPV4}
        ${IP_FAMILIES_IPV6}
EOF

# Create empty values files for charts that don't need configuration
for chart in namespaces rbac cilium coredns snapshot trust-manager trust-bundles sealed-secrets platform; do
  touch "${CURRENT}/_values/${chart}.yaml"
done

# Add Helm repositories from helmfile
helmfile repos

echo "Setup complete. Created _values directory with individual chart values files and added Helm repositories."
