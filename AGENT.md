# Nadrama.com Helm Charts - Agent Guide

## Commands
- **Render all charts**: `./render.sh` (generates manifests to `_rendered/`)
- **Install all charts**: `./install.sh` (installs all charts to Kubernetes current context)
- **Uninstall all charts**: `./uninstall.sh` (removes all charts from Kubernetes current context)
- **Single chart operations**: `./render.sh <chart-name>`, `./install.sh <chart-name>`, `./uninstall.sh <chart-name>`
- **Dependencies**: Requires `helm`, `helmfile`, `gcsplit` (from coreutils), `jq`, `yq`

Note: agents must NEVER run `./setup.sh`.

## Architecture
- **Core charts**: Critical infrastructure (cilium, coredns, cert-manager, traefik, cluster-wide, cluster-api-crds) managed by Nadrama not users
- **Addon charts**: Can later be installed/uninstalled if the user chooses
- **Default charts**: Pre-installed charts a user can edit (nadrama-hello)
- **Namespace convention**: Core & Addon charts use `system-` prefix plus chart name, Default charts use just chart name. For charts which only contain cluster-wide resources (e.g. CRD charts), we use the special `system-cluster` namespace, which should remain empty.
- **Network**: Dual-stack IPv4/IPv6 with specific CIDR blocks (Pod IPv4 `100.64.0.0/10` IPv6 `fd64::/48`, Service IPv4 `198.18.0.0/15` IPv6 `fdc6::/108`). CoreDNS IPv4 `198.19.255.254` IPv6 `fdc6::ffff`.
- **Structure**: Each chart has standard Helm chart files like Chart.yaml, values.yaml, templates/, optional dependencies in charts/

## Code Style
- **Helm charts**: Follow standard Helm conventions with dependencies in Chart.yaml
- **Bash scripts**: Use strict error handling (`set -eo pipefail`)
- **Chart ordering**: Critical - defined in config.sh arrays like INSTALL_CHARTS
- **Naming**: Use kebab-case for chart names, system- prefix for core namespaces
- **Dependencies**: External charts via Chart.yaml dependencies, not subcharts
