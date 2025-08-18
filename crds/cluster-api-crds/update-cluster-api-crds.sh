#!/usr/bin/env bash
# Copyright 2025 Nadrama Pty Ltd
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

CURRENT=$(dirname "$(readlink -f "$0")")
REPO_DIR=$(dirname "$CURRENT")
TEMP_DIR="$CURRENT/temp"
CAPI_CHART="$REPO_DIR/cluster-api/templates/external"
CRDS_CHART="$REPO_DIR/cluster-api-crds/templates/external"

# Create temp directory
mkdir "$TEMP_DIR"

# Get latest cluster-api version
# DL_VERSION="v1.9.3"
if [ -z "${DL_VERSION}" ]; then
    DL_VERSION=$(curl -fsSL "https://api.github.com/repos/kubernetes-sigs/cluster-api/releases/latest" | jq -r .tag_name)
fi
echo "${DL_VERSION}"

# Download latest core components YAML file
DL_URL="https://github.com/kubernetes-sigs/cluster-api/releases/download/${DL_VERSION}/core-components.yaml"
echo "curl -o ${TEMP_DIR}/core-components.yaml ${DL_URL}"
curl --show-error -L -o "${TEMP_DIR}/core-components.yaml" "${DL_URL}"

# Run envsubst (using the drone varient required by cluster-api)
go run github.com/drone/envsubst/v2/cmd/envsubst@latest < "${TEMP_DIR}/core-components.yaml" > "${TEMP_DIR}/core-components-subst.yaml"
mv "${TEMP_DIR}/core-components-subst.yaml" "${TEMP_DIR}/core-components.yaml"

# Change namespace from capi-system to system-cluster-api
sed -i '' 's/capi-system/system-cluster-api/' "${TEMP_DIR}/core-components.yaml"

# Split multi-document YAML file into separate YAML files
PREV=$(pwd)
cd "${TEMP_DIR}"
echo "yq -s '.metadata.name + \".yaml\"' core-components.yaml"
yq -s '.metadata.name + ".yaml"' "core-components.yaml"
rm "core-components.yaml"
cd "${PREV}"
echo "Done."

# Escape templates in description of clusterclasses CRD
echo '{{- define "raw.manifest" -}}' > "${TEMP_DIR}/clusterclasses.cluster.x-k8s.io.yaml.2"
cat "${TEMP_DIR}/clusterclasses.cluster.x-k8s.io.yaml" >> "${TEMP_DIR}/clusterclasses.cluster.x-k8s.io.yaml.2"
echo '{{- end -}}' >> "${TEMP_DIR}/clusterclasses.cluster.x-k8s.io.yaml.2"
mv "${TEMP_DIR}/clusterclasses.cluster.x-k8s.io.yaml.2" "${TEMP_DIR}/clusterclasses.cluster.x-k8s.io.yaml"

# Add leader election/lease config for CAPI CM
yq e '.spec.template.spec.containers[0].args += ["--leader-elect-lease-duration=75s", "--leader-elect-renew-deadline=65s", "--leader-elect-retry-period=15s"]' -i "${TEMP_DIR}/capi-controller-manager.yaml"

# Remove namespace resource
rm "${TEMP_DIR}/system-cluster-api.yaml"

# Update charts
mv $TEMP_DIR/*.cluster.x-k8s.io.yaml "$CRDS_CHART/"
mv $TEMP_DIR/*.yaml "$CAPI_CHART/"

# Clean up temp directory
rmdir "$TEMP_DIR"

echo "Please ensure both of the Chart.yml appVersion=${DL_VERSION}"
