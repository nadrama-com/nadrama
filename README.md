# Nadrama - Open Source container platform

Want to quickly deploy apps, containers, and agents on Kubernetes? The Nadrama platform is designed to make it easy.

We have combined proven Open Source components in a cohesive platform configuration, enabling you to turn a barebones Kubernetes cluster into an easy to use platform solution.

The Nadrama platform includes:

__Apps (and their CRDs):__

* [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) for continuous deployments (_Apache 2.0 license_).
* [Cert Manager](https://cert-manager.io/) for TLS certificate management (_Apache 2.0 license_).
* [Cilium](https://cilium.io/) for cluster networking & policies (_Apache 2.0 license_).
* [CoreDNS](https://coredns.io/) for DNS resolution (_Apache 2.0 license_).
* [AWS EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) for persistent storage on AWS (_Apache 2.0 license_).
* [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) for GitOps encrypted secrets (_Apache 2.0 license_).
* [Snapshot Controller](https://github.com/kubernetes-csi/external-snapshotter) for persistent volume snapshotting (_Apache 2.0 license_).
* [Traefik](https://traefik.io/) for ingress (_MIT license_).
* [Trust Manager](https://cert-manager.io/docs/trust/trust-manager/) for certificate trust store management (_Apache 2.0 license_).

__Additional CRDs:__

* [Cluster API CRDs](https://cluster-api.sigs.k8s.io/) for standardized auto-scaling APIs
* [Gateway API CRDs](https://gateway-api.sigs.k8s.io/) for standardized ingress APIs

__Defaults for:__

* RBAC
* Trust Bundles

All configuration in this repository is Open Source, released under the Apache 2.0 license.

## About Nadrama

This project is used as part of the [Nadrama Platform-as-a-Service (PaaS)](https://nadrama.com).

You can self-host this platform on an existing bare Kubernetes cluster, however if you would like an easy to use managed service so you can deploy faster and accelerate your teams, check out [Nadrama.com](https://nadrama.com).

Read more about [Nadrama's commitment to Open Source here](https://nadrama.com/opensource).

## Repository Overview

There are 3 types of charts:

1. CRD charts - we use separate charts for CRDs per [Helm Best Practices for CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#method-2-separate-charts).

2. App Charts - the main application charts.

3. Template Charts - templated charts designed to simplify deployment of your apps/containers/agents.


Note:

- We use [helmfile](https://helmfile.readthedocs.io/en/latest/) (_MIT license_) to handle the rendering/installation/uninstallation of all charts, via our shell scripts (see below).

- The `system-` prefix is used on charts/namespaces/resources to simplify RBAC rules / CEL policies.

## Usage

Setup a `values.yaml` file per app, stored under `_values`:

```
./setup.sh <ingress-hostname>
```

- Note that you may wish to store this in your own Git repo, if so, just symlink it to `_values`.

- Each of these files will be embedded into the corresponding ArgoCD application so changes are not overwritten during any ArgoCD syncs.

Render all charts to the `./_rendered` directory:

```
./render.sh (<single-chart>)
```

Install all (or single-chart of) charts into the current kubectl context:

```
./install.sh (<single-chart>)
```

Uninstall all (or single-chart of) charts from the current kubectl context:

```
./uninstall.sh (<single-chart>)
```

## Installation & Validating/Mutating Webhooks

There are runtime dependencies for some charts, for example:

* `trust-manager` requires the `cert-manager` `system-cert-manager-webhook` pod to be running
* `trust-bundles` requires the `trust-manager` `system-trust-manager` pod to be running

In both examples above, it's due to the ValidatingWebhookConfiguration and MutatingWebhookConfigurations created in the `cert-manager` and `trust-manager` charts, which are configured with a failurePolicy of `Fail` (fail closed).

When running `./install.sh` it will temporarily set the failurePolicy of those webhooks to `Ignore` (fail open). This should permit all charts to install correctly, in a single run. The `./install.sh` script uses a trap to attempt to restore the failurePolicy to `Ignore` once complete.

## Cluster Design & Assumptions

* We assume Kuberentes is configured with dual-stack IPv4 + IPv6.

  * Pod IPv4 CIDR block is `100.64.0.0/10`, supporting
    up to 4,194,304 IPv4 addresses. RFC 6598 reserves this CIDR block for
    reserved for Carrier-Grade NAT.

  * Pod IPv6 CIDR block is `fd64::/48`.

  * Service IPv4 CIDR block is `198.18.0.0/15`, supporting up to 131,072 IPv4
    addresses.

  * Service IPv6 CIDR block is `fdc6::/108`.

    * Note that kube-apiserver requires a prefix length >= 108.

  * Both IPv4 CIDR blocks are defined as private networks
    <https://en.wikipedia.org/wiki/Reserved_IP_addresses>

  * Both IPv4 CIDR blocks fall within the default set of eBPF-based
    nonMasqueradeCIDRs  <https://docs.cilium.io/en/stable/network/concepts/masquerading/>

  * Both IPv4 CIDR blocks are configured on `kube-controller-manager`.
    The service CIDR blocks are configured on `kube-apiserver`.
    We also configure per-Node CIDR blocks with `/24` prefix length for IPv4, and `/64` prefix length for IPv6.

* We configure Cilium CNI to use Kubernetes IPAM mode.

* CoreDNS runs as a DaemonSet

  * It uses the last service IPv4, `198.19.255.254`

  * It uses the last service IPv6, `fdc6::ffff`

  * The  kubelet is configured to use the above two addresses as clusterDNS.

## Testing

We use [Kind](https://kind.sigs.k8s.io/) to test the configuration locally.

Start the Kind cluster with:

```
kind create cluster --config kind.yaml
```

Delete the Kind cluster with:

```
kind delete cluster --name nadrama
```

## License

The contents of this repository is licensed under the Apache License, Version 2.0.
Copyright 2025 Nadrama Pty Ltd.
See [LICENSE](./LICENSE).
